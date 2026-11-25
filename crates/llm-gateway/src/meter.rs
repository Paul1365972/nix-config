use std::{
    mem,
    sync::Arc,
    time::{Duration, Instant},
};

use axum::{body::Body, http::header::CONTENT_TYPE};
use bytes::Bytes;
use futures_util::stream;
use memchr::{memchr, memmem};
use tokio::time::timeout;

use crate::{
    api::Api,
    gateway::{Gateway, Model},
    keys::{Key, RunningRequest},
    ledger::Charge,
    report::{CHAT_COMPLETIONS_STREAM_END, UsageReport},
    usage::Usage,
};

const CLOUDFLARE_IDLE_RESPONSE_LIMIT_SECONDS: u64 = 100;
const KEEPALIVE_INTERVAL: Duration =
    Duration::from_secs(CLOUDFLARE_IDLE_RESPONSE_LIMIT_SECONDS / 5);
const KEEPALIVE_COMMENT: Bytes = Bytes::from_static(b": keepalive\n\n");
const LINE_FEEDS_ENDING_EVENT: usize = 2;
const BUFFER_LIMIT_BYTES: usize = 32 * 1024 * 1024;

pub struct Meter {
    gateway: Arc<Gateway>,
    key: Arc<Key>,
    model: Arc<Model>,
    request_bytes: usize,
    sent: Instant,
    usage: UsageReader,
    is_billed_by_provider: bool,
    _running_request: RunningRequest,
}

impl Meter {
    pub fn start(
        gateway: Arc<Gateway>,
        key: Arc<Key>,
        model: Arc<Model>,
        api: Api,
        request_bytes: usize,
        running_request: RunningRequest,
    ) -> Self {
        Self {
            gateway,
            key,
            model,
            request_bytes,
            sent: Instant::now(),
            usage: UsageReader::new(api),
            is_billed_by_provider: true,
            _running_request: running_request,
        }
    }

    pub fn leave_unbilled(mut self) {
        self.is_billed_by_provider = false;
    }
}

impl Drop for Meter {
    fn drop(&mut self) {
        if !self.is_billed_by_provider {
            return;
        }
        let (key, model) = (&self.key.name, &self.model.name);
        let estimate = Usage::estimate(self.request_bytes, self.sent.elapsed());
        let (usage, is_estimated) = match self.usage.reported {
            Some(last_usage) if self.usage.has_reported_last => (last_usage, false),
            Some(usage_before_break) => {
                let output_tokens = usage_before_break.output_tokens.max(estimate.output_tokens);
                let usage = Usage {
                    output_tokens,
                    ..usage_before_break
                };
                (usage, true)
            }
            None => (estimate, true),
        };
        if is_estimated {
            tracing::warn!(%key, %model, "a response ended without its usage and is charged an estimate");
        }
        let cost = self.model.cost(&usage);
        tracing::info!(
            %key, %model,
            uncached_input_tokens = usage.uncached_input_tokens,
            cache_read_tokens = usage.cache_read_tokens,
            cache_write_tokens = usage.cache_write_tokens.total(),
            output_tokens = usage.output_tokens,
            web_searches = usage.web_searches,
            cost_usd = cost.usd(),
            "charged"
        );
        let charge = Charge {
            usage,
            cost,
            is_estimated,
        };
        self.gateway.ledger.record(key, model, &charge);
    }
}

pub fn relay(upstream: reqwest::Response, mut meter: Meter) -> Body {
    let media_type = upstream.headers().get(CONTENT_TYPE);
    let media_type = media_type.and_then(|media_type| media_type.to_str().ok());
    meter.usage.is_event_stream =
        media_type.is_some_and(|media_type| media_type.starts_with("text/event-stream"));
    let stream_begins_between_events = LINE_FEEDS_ENDING_EVENT;
    let relay = Relay {
        upstream,
        meter,
        trailing_line_feeds: stream_begins_between_events,
    };
    Body::from_stream(stream::unfold(Some(relay), |relay| async {
        let mut relay = relay?;
        let chunk = relay.next_chunk_or_keepalive().await?;
        let continues = chunk.is_ok();
        Some((chunk, continues.then_some(relay)))
    }))
}

struct UsageReader {
    api: Api,
    is_event_stream: bool,
    unfinished_line_or_document: Vec<u8>,
    is_over_buffer_limit: bool,
    reported: Option<Usage>,
    has_reported_last: bool,
}

impl UsageReader {
    fn new(api: Api) -> Self {
        Self {
            api,
            is_event_stream: false,
            unfinished_line_or_document: Vec::new(),
            is_over_buffer_limit: false,
            reported: None,
            has_reported_last: false,
        }
    }

    fn read_chunk(&mut self, mut chunk: &[u8]) {
        while self.is_event_stream
            && let Some(line_end) = memchr(b'\n', chunk)
        {
            let (line, rest) = chunk.split_at(line_end);
            chunk = &rest[1..];
            if self.unfinished_line_or_document.is_empty() {
                self.read_line(line);
            } else {
                self.buffer(line);
                let line = mem::take(&mut self.unfinished_line_or_document);
                self.read_line(&line);
            }
            self.is_over_buffer_limit = false;
        }
        self.buffer(chunk);
    }

    fn buffer(&mut self, bytes: &[u8]) {
        if self.unfinished_line_or_document.len() + bytes.len() > BUFFER_LIMIT_BYTES {
            self.is_over_buffer_limit = true;
            self.unfinished_line_or_document = Vec::new();
        }
        if !self.is_over_buffer_limit {
            self.unfinished_line_or_document.extend_from_slice(bytes);
        }
    }

    fn read_line(&mut self, line: &[u8]) {
        let Some(data) = line.strip_prefix(b"data:") else {
            return;
        };
        if data.trim_ascii() == CHAT_COMPLETIONS_STREAM_END {
            self.has_reported_last = true;
        } else if !self.is_over_buffer_limit && memmem::find(data, b"\"usage\"").is_some() {
            self.read_json(data);
        }
    }

    fn read_json(&mut self, json: &[u8]) {
        if let Some(report) = UsageReport::read(self.api, json) {
            let earlier = self.reported.unwrap_or_default();
            self.reported = Some(earlier.with_later_running_counts(report.usage));
            self.has_reported_last |= report.is_last;
        }
    }

    fn read_document_at_its_end(&mut self) {
        if !self.is_event_stream {
            let document = mem::take(&mut self.unfinished_line_or_document);
            self.read_json(&document);
            self.has_reported_last = true;
        }
    }
}

struct Relay {
    upstream: reqwest::Response,
    meter: Meter,
    trailing_line_feeds: usize,
}

impl Relay {
    async fn next_chunk_or_keepalive(&mut self) -> Option<reqwest::Result<Bytes>> {
        let is_between_events =
            self.meter.usage.is_event_stream && self.trailing_line_feeds >= LINE_FEEDS_ENDING_EVENT;
        let chunk = if is_between_events {
            match timeout(KEEPALIVE_INTERVAL, self.upstream.chunk()).await {
                Ok(chunk) => chunk,
                Err(_) => return Some(Ok(KEEPALIVE_COMMENT)),
            }
        } else {
            self.upstream.chunk().await
        };
        match chunk {
            Ok(Some(chunk)) => {
                self.meter.usage.read_chunk(&chunk);
                self.count_trailing_line_feeds(&chunk);
                Some(Ok(chunk))
            }
            Ok(None) => {
                self.meter.usage.read_document_at_its_end();
                None
            }
            Err(error) => {
                let error = error.without_url();
                tracing::warn!(model = %self.meter.model.name, %error, "the provider's response broke off");
                Some(Err(error))
            }
        }
    }

    fn count_trailing_line_feeds(&mut self, chunk: &[u8]) {
        let mut line_feeds = 0;
        for &byte in chunk.iter().rev() {
            match byte {
                b'\n' => line_feeds += 1,
                b'\r' => {}
                _ => {
                    self.trailing_line_feeds = line_feeds;
                    return;
                }
            }
        }
        self.trailing_line_feeds += line_feeds;
    }
}
