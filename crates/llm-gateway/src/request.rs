use std::{borrow::Cow, collections::BTreeMap, fmt, ops::Range};

use bytes::Bytes;
use memchr::memchr;
use serde::de::{DeserializeSeed, Deserializer, Error, IgnoredAny, MapAccess, Visitor};
use serde_json::{Map, Value, json, value::RawValue};

use crate::{
    api::{Api, ListPriceChoice},
    refusal::Refusal,
};

const MODEL: &str = "model";
const STREAM: &str = "stream";
const STREAM_OPTIONS: &str = "stream_options";
const BACKGROUND: &str = "background";
const FIELDS_READ: [&str; 4] = [MODEL, STREAM, STREAM_OPTIONS, BACKGROUND];

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
        let fields = TopLevelFields { api }
            .deserialize(&mut json)
            .map_err(unreadable)?;
        json.end().map_err(unreadable)?;
        Ok(Self { body, api, fields })
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

    pub fn require_list_price(&self) -> Result<(), Refusal> {
        if self.field(BACKGROUND) == "true" {
            return Err(Refusal::invalid_request(
                "background_unsupported",
                "The gateway serves no background responses, whose cost arrives after the response.",
            ));
        }
        let costs_more = |choice: &&ListPriceChoice| {
            let given = self.field(choice.field);
            let is_left_out = given.is_empty() || given == "null";
            !is_left_out && serde_json::from_str::<&str>(given).ok() != Some(choice.value)
        };
        match self.api.list_price_choices().iter().find(costs_more) {
            None => Ok(()),
            Some(ListPriceChoice { field, value }) => Err(Refusal::invalid_request(
                "list_price_only",
                format!("The gateway serves {field} only as {value:?}, or left out."),
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

    fn field(&self, name: &str) -> &'body str {
        self.fields.get(name).map_or("", |value| value.get())
    }

    fn byte_range_of(&self, name: &str) -> Range<usize> {
        let value = self.field(name);
        let start = value.as_ptr() as usize - self.body.as_ptr() as usize;
        start..start + value.len()
    }
}

struct TopLevelFields {
    api: Api,
}

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
        let list_price_choices = self.api.list_price_choices();
        let mut fields = BTreeMap::new();
        while let Some(name) = object.next_key::<Cow<str>>()? {
            let is_read = FIELDS_READ.contains(&&*name)
                || list_price_choices.iter().any(|choice| choice.field == name);
            if !is_read {
                object.next_value::<IgnoredAny>()?;
                continue;
            }
            let value = object.next_value()?;
            let is_named_twice = fields.insert(name.into_owned(), value).is_some();
            if is_named_twice {
                return Err(A::Error::custom("a field is named twice"));
            }
        }
        Ok(fields)
    }
}
