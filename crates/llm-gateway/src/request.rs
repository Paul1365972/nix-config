use std::{borrow::Cow, collections::BTreeMap, fmt, ops::Range};

use bytes::Bytes;
use memchr::memchr;
use serde::de::{DeserializeSeed, Deserializer, Error, MapAccess, Visitor};
use serde_json::{Map, Value, json, value::RawValue};

use crate::{
    api::{Api, Fields, FixedField, Work},
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
        request.require_known_tools_and_nothing_stored()?;
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

    pub fn upstream_body(&self, model_name_carries_provider: bool, work: Work) -> Bytes {
        let mut replacements = Vec::new();
        let mut fields_stated_for_the_client = String::new();
        let mut state = |name: &str, json: &str| {
            fields_stated_for_the_client.push_str(&format!("{}:{json},", json!(name)));
        };
        if model_name_carries_provider {
            let model_name: String = serde_json::from_str(self.field(MODEL)).unwrap_or_default();
            let model_without_provider = model_name.split_once('/').map_or("", |(_, model)| model);
            replacements.push((
                self.byte_range_of(MODEL),
                json!(model_without_provider).to_string(),
            ));
        }
        let stream_reports_usage_only_when_asked =
            self.api == Api::ChatCompletions && self.field(STREAM) == "true";
        if stream_reports_usage_only_when_asked {
            let mut options: Map<String, Value> =
                serde_json::from_str(self.field(STREAM_OPTIONS)).unwrap_or_default();
            options.insert("include_usage".to_owned(), true.into());
            let options = Value::from(options).to_string();
            match self.fields.contains_key(STREAM_OPTIONS) {
                true => replacements.push((self.byte_range_of(STREAM_OPTIONS), options)),
                false => state(STREAM_OPTIONS, &options),
            }
        }
        let stated_when_left_out = match work {
            Work::Answer => self.api.fields().stated_when_left_out,
            Work::CountTokens => &[],
        };
        for FixedField { name, json } in stated_when_left_out {
            match self.fields.contains_key(*name) {
                true if self.field(name) == NULL => {
                    replacements.push((self.byte_range_of(name), (*json).to_owned()));
                }
                true => {}
                false => state(name, json),
            }
        }
        if !fields_stated_for_the_client.is_empty() {
            let after_opening_brace = memchr(b'{', self.body).map_or(0, |brace| brace + 1);
            replacements.push((
                after_opening_brace..after_opening_brace,
                fields_stated_for_the_client,
            ));
        }
        if replacements.is_empty() {
            return self.body.clone();
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
            ..
        } = self.api.fields();
        for (name, value) in &self.fields {
            let given = value.get();
            match passed_only_as.iter().find(|field| field.name == name) {
                Some(FixedField { json, .. }) if given != *json && given != NULL => {
                    return Err(Refusal::invalid_request(
                        "value_unsupported",
                        format!("The gateway passes on {name} only as {json}, or left out."),
                    ));
                }
                Some(_) => {}
                None if passed_as_given.contains(&name.as_str()) => {}
                None => {
                    return Err(Refusal::invalid_request(
                        "field_unsupported",
                        format!("The gateway does not pass on the field {name:?}."),
                    ));
                }
            }
        }
        Ok(())
    }

    fn require_known_tools_and_nothing_stored(&self) -> Result<(), Refusal> {
        for tool in &self.items_of(TOOLS)? {
            self.require_known_tool(tool)?;
        }
        for turn in &self.items_of(self.api.fields().conversation)? {
            let refers_to_stored_item = turn["type"] == "item_reference";
            let blocks = || items(&turn["content"]).chain(items(&turn["output"]));
            let blocks_of_tool_results = blocks().flat_map(|block| items(&block["content"]));
            let mut blocks = blocks().chain(blocks_of_tool_results);
            let refers_to_stored_file = |block: &Value| {
                let file_is_named_by = [block, &block["file"], &block["source"]];
                file_is_named_by
                    .iter()
                    .any(|holder| !holder["file_id"].is_null())
            };
            if refers_to_stored_item || blocks.clone().any(refers_to_stored_file) {
                return Err(Refusal::invalid_request(
                    "reference_unsupported",
                    "The gateway does not pass on a reference to something stored at the provider.",
                ));
            }
            let tools_added_by_openai_client = items(&turn["tools"]);
            let tools_added_by_anthropic_client = blocks
                .by_ref()
                .map(|block| &block["tool"]["definition"])
                .filter(|definition| !definition.is_null());
            for tool in tools_added_by_openai_client.chain(tools_added_by_anthropic_client) {
                self.require_known_tool(tool)?;
            }
        }
        Ok(())
    }

    fn require_known_tool(&self, tool: &Value) -> Result<(), Refusal> {
        let kind = tool["type"].as_str();
        if !self.api.passes_tool_on(kind) {
            let tool = match kind {
                Some(kind) => format!("a tool of type {kind:?}"),
                None => "a tool that names no type".to_owned(),
            };
            return Err(Refusal::invalid_request(
                "tool_unsupported",
                format!("The gateway does not pass on {tool}."),
            ));
        }
        let tools_of_namespace = items(&tool["tools"]);
        for tool in tools_of_namespace {
            self.require_known_tool(tool)?;
        }
        Ok(())
    }

    fn items_of(&self, list_field: &str) -> Result<Vec<Value>, Refusal> {
        match serde_json::from_str(self.field(list_field)) {
            Ok(Value::Array(items)) => Ok(items),
            Ok(Value::Null | Value::String(_)) => Ok(Vec::new()),
            _ => Err(Refusal::invalid_request(
                "invalid_body",
                format!("The gateway cannot read the field {list_field:?}."),
            )),
        }
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

fn items(list: &Value) -> impl Iterator<Item = &Value> + Clone {
    list.as_array().into_iter().flatten()
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
