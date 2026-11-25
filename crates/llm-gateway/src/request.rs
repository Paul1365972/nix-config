use std::{borrow::Cow, collections::BTreeMap, fmt, marker::PhantomData, ops::Range};

use bytes::Bytes;
use memchr::memchr;
use serde::{
    Deserialize,
    de::{DeserializeSeed, Deserializer, Error, MapAccess, SeqAccess, Visitor},
};
use serde_json::{Map, Value, json, value::RawValue};

use crate::{
    api::{Api, Fields, FixedField},
    refusal::Refusal,
};

const MODEL: &str = "model";
const STREAM: &str = "stream";
const STREAM_OPTIONS: &str = "stream_options";
const TOOLS: &str = "tools";
const NULL: &str = "null";

pub struct Request<'body> {
    body: &'body Bytes,
    api: Api,
    fields: BTreeMap<String, &'body RawValue>,
}

impl<'body> Request<'body> {
    pub fn read(body: &'body Bytes, api: Api) -> Result<Self, Refusal> {
        let unreadable = |_| {
            Refusal::invalid_request(
                "invalid_body",
                "The request body is not a JSON object, or names a field twice.",
            )
        };
        let mut json = serde_json::Deserializer::from_slice(body);
        let fields = TopLevelFields.deserialize(&mut json).map_err(unreadable)?;
        json.end().map_err(unreadable)?;
        let request = Self { body, api, fields };
        request.require_known_fields()?;
        request.require_known_tools()?;
        Ok(request)
    }

    pub fn model_name(&self, route_provider: Option<&str>) -> Result<String, Refusal> {
        let model: String = serde_json::from_str(self.field(MODEL)).map_err(|_| {
            Refusal::invalid_request("invalid_model", "The request names no model.")
        })?;
        match route_provider {
            Some(provider) => Ok(format!("{provider}/{model}")),
            None if model.contains('/') => Ok(model),
            None => Err(Refusal::invalid_request(
                "invalid_model",
                "This API names a model provider/model.",
            )),
        }
    }

    pub fn upstream_body(&self, model_name_carries_provider: bool) -> Bytes {
        if !model_name_carries_provider {
            return self.body.clone();
        }
        let model_name: String = serde_json::from_str(self.field(MODEL)).unwrap_or_default();
        let model_without_provider = model_name.split_once('/').map_or("", |(_, model)| model);
        let mut replacements = vec![(
            self.byte_range_of(MODEL),
            json!(model_without_provider).to_string(),
        )];
        let stream_reports_usage_only_when_asked = self.field(STREAM) == "true";
        if stream_reports_usage_only_when_asked {
            let mut options: Map<String, Value> =
                serde_json::from_str(self.field(STREAM_OPTIONS)).unwrap_or_default();
            options.insert("include_usage".to_owned(), true.into());
            let options = Value::from(options).to_string();
            replacements.push(match self.fields.contains_key(STREAM_OPTIONS) {
                true => (self.byte_range_of(STREAM_OPTIONS), options),
                false => {
                    let after_opening_brace = memchr(b'{', self.body).map_or(0, |brace| brace + 1);
                    let field = format!("{}:{options},", json!(STREAM_OPTIONS));
                    (after_opening_brace..after_opening_brace, field)
                }
            });
        }
        replacements.sort_by_key(|(range, _)| range.start);

        let mut upstream_body = Vec::with_capacity(self.body.len() + 64);
        let mut copied_until = 0;
        for (range, replacement) in replacements {
            upstream_body.extend_from_slice(&self.body[copied_until..range.start]);
            upstream_body.extend_from_slice(replacement.as_bytes());
            copied_until = range.end;
        }
        upstream_body.extend_from_slice(&self.body[copied_until..]);
        upstream_body.into()
    }

    fn require_known_fields(&self) -> Result<(), Refusal> {
        let Fields {
            passed_as_given,
            passed_only_as,
            passed_only_stated_as,
            ..
        } = self.api.fields();
        let value_unsupported =
            |message: String| Err(Refusal::invalid_request("value_unsupported", message));
        for (name, value) in &self.fields {
            let given = value.get();
            let is_named = |field: &&FixedField| field.name == name;
            if let Some(FixedField { json, .. }) = passed_only_as.iter().find(is_named) {
                if given != *json && given != NULL {
                    return value_unsupported(format!(
                        "The gateway passes on {name} only as {json}, or left out."
                    ));
                }
            } else if passed_only_stated_as.iter().find(is_named).is_none()
                && !passed_as_given.contains(&name.as_str())
            {
                return Err(Refusal::invalid_request(
                    "field_unsupported",
                    format!("The gateway does not pass on the field {name:?}."),
                ));
            }
        }
        let is_stated_otherwise = |field: &&FixedField| self.field(field.name) != field.json;
        match passed_only_stated_as.iter().find(is_stated_otherwise) {
            None => Ok(()),
            Some(FixedField { name, json }) => value_unsupported(format!(
                "The gateway passes on {name} only as {json}, which the request must state."
            )),
        }
    }

    fn require_known_tools(&self) -> Result<(), Refusal> {
        let declared: Vec<Tool> = self.items_of(TOOLS)?;
        let turns: Vec<Turn> = self.items_of(self.api.fields().conversation)?;
        declared
            .iter()
            .chain(turns.iter().flat_map(Turn::tools_added))
            .try_for_each(|tool| tool.require_passed_on(self.api))
    }

    fn items_of<T: Deserialize<'body>>(&self, list_field: &str) -> Result<Vec<T>, Refusal> {
        let ItemsOfList(items) = serde_json::from_str(self.field(list_field)).map_err(|_| {
            Refusal::invalid_request(
                "invalid_body",
                format!("The gateway cannot read the field {list_field:?}."),
            )
        })?;
        Ok(items)
    }

    fn field(&self, name: &str) -> &'body str {
        self.fields.get(name).map_or(NULL, |value| value.get())
    }

    fn byte_range_of(&self, name: &str) -> Range<usize> {
        let value = self.field(name);
        let start = value.as_ptr() as usize - self.body.as_ptr() as usize;
        start..start + value.len()
    }
}

struct TopLevelFields;

impl<'de> DeserializeSeed<'de> for TopLevelFields {
    type Value = BTreeMap<String, &'de RawValue>;

    fn deserialize<D: Deserializer<'de>>(self, deserializer: D) -> Result<Self::Value, D::Error> {
        deserializer.deserialize_map(self)
    }
}

impl<'de> Visitor<'de> for TopLevelFields {
    type Value = BTreeMap<String, &'de RawValue>;

    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str("a JSON object")
    }

    fn visit_map<A: MapAccess<'de>>(self, mut object: A) -> Result<Self::Value, A::Error> {
        let mut fields = BTreeMap::new();
        while let Some((name, value)) = object.next_entry::<Cow<str>, _>()? {
            let is_named_twice = fields.insert(name.into_owned(), value).is_some();
            if is_named_twice {
                return Err(A::Error::custom("a field is named twice"));
            }
        }
        Ok(fields)
    }
}

#[derive(Deserialize)]
struct Tool {
    #[serde(rename = "type")]
    kind: Option<String>,
    #[serde(default, rename = "tools")]
    tools_of_namespace: ItemsOfList<Tool>,
}

impl Tool {
    fn require_passed_on(&self, api: Api) -> Result<(), Refusal> {
        if !api.passes_tool_on(self.kind.as_deref()) {
            let tool = match &self.kind {
                Some(kind) => format!("a tool of type {kind:?}"),
                None => "a tool that names no type".to_owned(),
            };
            return Err(Refusal::invalid_request(
                "tool_unsupported",
                format!("The gateway does not pass on {tool}."),
            ));
        }
        let ItemsOfList(tools_of_namespace) = &self.tools_of_namespace;
        tools_of_namespace
            .iter()
            .try_for_each(|tool| tool.require_passed_on(api))
    }
}

#[derive(Deserialize)]
struct Turn {
    #[serde(default, rename = "tools")]
    tools_added_by_openai_client: ItemsOfList<Tool>,
    #[serde(default)]
    content: ItemsOfList<Block>,
}

impl Turn {
    fn tools_added(&self) -> impl Iterator<Item = &Tool> {
        let ItemsOfList(by_openai_client) = &self.tools_added_by_openai_client;
        let ItemsOfList(blocks) = &self.content;
        let by_anthropic_client = blocks
            .iter()
            .filter_map(|block| block.tool_added_or_removed.as_ref()?.definition.as_ref());
        by_openai_client.iter().chain(by_anthropic_client)
    }
}

#[derive(Deserialize)]
struct Block {
    #[serde(rename = "tool")]
    tool_added_or_removed: Option<ToolUpdate>,
}

#[derive(Deserialize)]
struct ToolUpdate {
    definition: Option<Tool>,
}

struct ItemsOfList<T>(Vec<T>);

impl<T> Default for ItemsOfList<T> {
    fn default() -> Self {
        Self(Vec::new())
    }
}

impl<'de, T: Deserialize<'de>> Deserialize<'de> for ItemsOfList<T> {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        deserializer.deserialize_any(ListOrTextOrNull(PhantomData))
    }
}

struct ListOrTextOrNull<T>(PhantomData<T>);

impl<'de, T: Deserialize<'de>> Visitor<'de> for ListOrTextOrNull<T> {
    type Value = ItemsOfList<T>;

    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str("a list, text or null")
    }

    fn visit_seq<A: SeqAccess<'de>>(self, mut list: A) -> Result<Self::Value, A::Error> {
        let mut items = Vec::new();
        while let Some(item) = list.next_element()? {
            items.push(item);
        }
        Ok(ItemsOfList(items))
    }

    fn visit_str<E>(self, _text: &str) -> Result<Self::Value, E> {
        Ok(ItemsOfList::default())
    }

    fn visit_unit<E>(self) -> Result<Self::Value, E> {
        Ok(ItemsOfList::default())
    }
}
