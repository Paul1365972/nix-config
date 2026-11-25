use axum::{
    Json,
    http::{HeaderName, HeaderValue, StatusCode, header::RETRY_AFTER},
    response::{IntoResponse, Response},
};
use serde_json::json;

pub const X_SHOULD_RETRY: HeaderName = HeaderName::from_static("x-should-retry");

#[derive(Debug)]
pub struct Refusal {
    status: StatusCode,
    kind: &'static str,
    code: &'static str,
    message: String,
    retry_after_seconds: Option<u64>,
}

impl Refusal {
    pub fn new(
        status: StatusCode,
        kind: &'static str,
        code: &'static str,
        message: impl Into<String>,
    ) -> Self {
        Self {
            status,
            kind,
            code,
            message: message.into(),
            retry_after_seconds: None,
        }
    }

    pub fn invalid_request(code: &'static str, message: impl Into<String>) -> Self {
        Self::new(
            StatusCode::BAD_REQUEST,
            "invalid_request_error",
            code,
            message,
        )
    }

    pub fn retry_after_seconds(mut self, seconds: u64) -> Self {
        self.retry_after_seconds = Some(seconds);
        self
    }
}

impl IntoResponse for Refusal {
    fn into_response(self) -> Response {
        let error_as_openai_clients_read_it =
            json!({ "message": self.message, "type": self.kind, "code": self.code });
        let error_as_anthropic_clients_read_it_too =
            json!({ "type": "error", "error": error_as_openai_clients_read_it });
        let body = Json(error_as_anthropic_clients_read_it_too);
        let mut response = (self.status, body).into_response();
        let headers = response.headers_mut();
        let sdks_retry_client_errors_unless_told_not_to = self.status.is_client_error();
        if let Some(seconds) = self.retry_after_seconds {
            headers.insert(RETRY_AFTER, HeaderValue::from(seconds));
            headers.insert(X_SHOULD_RETRY, HeaderValue::from_static("true"));
        } else if sdks_retry_client_errors_unless_told_not_to {
            headers.insert(X_SHOULD_RETRY, HeaderValue::from_static("false"));
        }
        response
    }
}
