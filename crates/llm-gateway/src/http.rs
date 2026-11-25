use std::{future::IntoFuture, net::SocketAddr, sync::Arc, time::Duration};

use anyhow::{Context, Result};
use axum::{
    Json, Router,
    body::{Body, to_bytes},
    extract::{Path, Request, State},
    http::{
        HeaderMap, HeaderName, HeaderValue, StatusCode,
        header::{AUTHORIZATION, CONTENT_TYPE, RETRY_AFTER},
    },
    response::Response,
    routing::{get, post},
    serve::ListenerExt,
};
use chrono::Days;
use serde_json::{Value, json};
use tokio::time::sleep;
use tokio_util::sync::CancellationToken;

use crate::{
    api::{Api, X_API_KEY},
    dashboard,
    gateway::Gateway,
    keys::Key,
    ledger::today,
    meter::{Meter, relay},
    page,
    price::MicroUsd,
    refusal::{Refusal, X_SHOULD_RETRY},
    request::Request as RequestBody,
};

const REQUEST_BODY_LIMIT_BYTES: usize = 32 * 1024 * 1024;
const DRAIN_LIMIT: Duration = Duration::from_secs(30);
const DAYS_SHOWN: u64 = 30;

const FORWARDED_REQUEST_HEADERS: [HeaderName; 3] = [
    HeaderName::from_static("anthropic-version"),
    HeaderName::from_static("anthropic-beta"),
    HeaderName::from_static("openai-beta"),
];

const FORWARDED_RESPONSE_HEADERS: [HeaderName; 6] = [
    CONTENT_TYPE,
    RETRY_AFTER,
    HeaderName::from_static("retry-after-ms"),
    X_SHOULD_RETRY,
    HeaderName::from_static("request-id"),
    HeaderName::from_static("x-request-id"),
];

pub async fn serve(
    gateway: Arc<Gateway>,
    listen: SocketAddr,
    dashboard_listen: SocketAddr,
) -> Result<()> {
    let router = Router::new()
        .merge(page::usage_routes())
        .route("/v1/chat/completions", post(complete_chat))
        .route("/{provider}/v1/messages", post(create_message))
        .route("/{provider}/v1/responses", post(create_response))
        .route("/v1/models", get(models))
        .route("/v1/usage", get(usage))
        .route("/health", get(health))
        .with_state(gateway.clone());
    let listener = bind(listen).await?;
    let dashboard_listener = bind(dashboard_listen).await?;
    tracing::info!(%listen, %dashboard_listen, "serving");

    let stopping = CancellationToken::new();
    tokio::spawn({
        let stopping = stopping.clone();
        async move {
            stop_signal().await;
            stopping.cancel();
        }
    });
    let serving = axum::serve(listener, router)
        .with_graceful_shutdown(stopping.clone().cancelled_owned())
        .into_future();
    let serving_dashboard =
        axum::serve(dashboard_listener, dashboard::router_without_login(gateway))
            .with_graceful_shutdown(stopping.clone().cancelled_owned())
            .into_future();
    tokio::select! {
        served = async { tokio::try_join!(serving, serving_dashboard) } => {
            served.map(drop).context("serving HTTP")
        }
        () = async { stopping.cancelled().await; sleep(DRAIN_LIMIT).await } => {
            tracing::warn!("stopping with responses still running, which are charged what they had reported");
            Ok(())
        }
    }
}

async fn bind(address: SocketAddr) -> Result<impl axum::serve::Listener<Addr = SocketAddr>> {
    let listener = tokio::net::TcpListener::bind(address)
        .await
        .with_context(|| format!("listening on {address}"))?;
    Ok(listener.tap_io(|connection| {
        let _ = connection.set_nodelay(true);
    }))
}

async fn stop_signal() {
    let interrupt = async {
        let _ = tokio::signal::ctrl_c().await;
    };
    #[cfg(unix)]
    {
        use tokio::signal::unix::{SignalKind, signal};
        match signal(SignalKind::terminate()) {
            Ok(mut terminate) => tokio::select! {
                _ = interrupt => {}
                _ = terminate.recv() => {}
            },
            Err(_) => interrupt.await,
        }
    }
    #[cfg(not(unix))]
    interrupt.await;
}

async fn complete_chat(
    State(gateway): State<Arc<Gateway>>,
    request: Request,
) -> Result<Response, Refusal> {
    forward(gateway, Api::ChatCompletions, None, request).await
}

async fn create_message(
    State(gateway): State<Arc<Gateway>>,
    Path(provider): Path<String>,
    request: Request,
) -> Result<Response, Refusal> {
    forward(gateway, Api::Messages, Some(&provider), request).await
}

async fn create_response(
    State(gateway): State<Arc<Gateway>>,
    Path(provider): Path<String>,
    request: Request,
) -> Result<Response, Refusal> {
    forward(gateway, Api::Responses, Some(&provider), request).await
}

async fn forward(
    gateway: Arc<Gateway>,
    api: Api,
    route_provider: Option<&str>,
    request: Request,
) -> Result<Response, Refusal> {
    let key = authenticate(&gateway, request.headers())?;
    let running_request = gateway.run_request(&key)?;
    let (parts, body) = request.into_parts();
    let body = to_bytes(body, REQUEST_BODY_LIMIT_BYTES).await.map_err(|_| {
        Refusal::invalid_request(
            "unreadable_body",
            format!("The request body could not be read; it may hold at most {REQUEST_BODY_LIMIT_BYTES} bytes."),
        )
    })?;
    let request = RequestBody::read(&body, api)?;
    request.require_list_price()?;
    let model = gateway.model_served(&key, api, &request.model_name(route_provider)?)?;
    let provider = model.provider.clone();
    let model_name_carries_provider = route_provider.is_none();
    let upstream_body = request.upstream_body(model_name_carries_provider);

    let query = parts.uri.query().map(|query| format!("?{query}"));
    let url = format!(
        "{}{}{}",
        provider.base_url,
        api.path(),
        query.unwrap_or_default()
    );
    let mut headers = HeaderMap::new();
    let (credential, value) = api.credentials(&provider);
    headers.insert(credential, value);
    headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
    for name in FORWARDED_REQUEST_HEADERS {
        for value in parts.headers.get_all(&name) {
            headers.append(name.clone(), value.clone());
        }
    }

    let sending = gateway
        .client
        .post(url)
        .headers(headers)
        .body(upstream_body);
    let meter = Meter::start(gateway, key, model, api, running_request);
    let upstream = match sending.send().await {
        Ok(upstream) => upstream,
        Err(error) => {
            let never_reached_provider = error.is_connect();
            let error = error.without_url();
            tracing::warn!(provider = provider.name, %error, "the provider did not answer");
            if never_reached_provider {
                meter.leave_unbilled();
            }
            return Err(Refusal::new(
                StatusCode::BAD_GATEWAY,
                "api_error",
                "provider_unreachable",
                format!("The provider {} did not answer.", provider.name),
            ));
        }
    };

    let status = upstream.status();
    let provider_refused_gateway_key = status == StatusCode::UNAUTHORIZED;
    if provider_refused_gateway_key {
        tracing::error!(
            provider = provider.name,
            "the provider refused the gateway's own key"
        );
        meter.leave_unbilled();
        return Err(Refusal::new(
            StatusCode::BAD_GATEWAY,
            "api_error",
            "provider_refused_gateway",
            format!("The provider {} refused the gateway.", provider.name),
        ));
    }

    let mut response = Response::new(Body::empty());
    *response.status_mut() = status;
    for name in FORWARDED_RESPONSE_HEADERS {
        for value in upstream.headers().get_all(&name) {
            response.headers_mut().append(name.clone(), value.clone());
        }
    }
    let is_billed_by_provider = status.is_success();
    *response.body_mut() = if is_billed_by_provider {
        relay(upstream, meter)
    } else {
        meter.leave_unbilled();
        Body::new(reqwest::Body::from(upstream))
    };
    Ok(response)
}

fn authenticate(gateway: &Gateway, headers: &HeaderMap) -> Result<Arc<Key>, Refusal> {
    let header = |name| headers.get(name).and_then(|value| value.to_str().ok());
    let token_of_anthropic_client = header(X_API_KEY).filter(|token| !token.is_empty());
    let token_of_openai_client = header(AUTHORIZATION).and_then(|value| {
        let (scheme, token) = value.split_once(' ')?;
        scheme.eq_ignore_ascii_case("bearer").then_some(token)
    });
    let token = token_of_anthropic_client.or(token_of_openai_client);
    let key = token.and_then(|token| gateway.keys.with_token(token.trim()));
    key.ok_or_else(|| {
        Refusal::new(
            StatusCode::UNAUTHORIZED,
            "authentication_error",
            "invalid_api_key",
            "The request carries no valid key.",
        )
    })
}

async fn models(
    State(gateway): State<Arc<Gateway>>,
    headers: HeaderMap,
) -> Result<Json<Value>, Refusal> {
    authenticate(&gateway, &headers)?;
    let models: Vec<Value> = gateway
        .models()
        .filter(|model| model.provider.serves(Api::ChatCompletions))
        .map(|model| {
            json!({ "id": model.name, "object": "model", "created": 0, "owned_by": model.provider.name })
        })
        .collect();
    Ok(Json(json!({ "object": "list", "data": models })))
}

async fn usage(
    State(gateway): State<Arc<Gateway>>,
    headers: HeaderMap,
) -> Result<Json<Value>, Refusal> {
    let key = authenticate(&gateway, &headers)?;
    let spent_by_provider = gateway.spent_on_every_provider(&key);
    let today = today();
    let last_days = today - Days::new(DAYS_SHOWN - 1)..=today;
    Ok(Json(json!({
        "key": key.name,
        "limit_usd": key.settings.limit_usd,
        "limit_usd_by_provider": key.settings.limit_usd_by_provider,
        "limit_resets": key.settings.limit_resets,
        "limit_requests_at_once": key.settings.limit_requests_at_once,
        "limit_resets_on": key.limit_resets_on(),
        "running_requests": key.running_requests(),
        "spent_usd": spent_by_provider.values().copied().sum::<MicroUsd>(),
        "spent_usd_by_provider": spent_by_provider,
        "models": gateway.ledger.models_since(&key.name, key.period_start()),
        "today": today,
        "days": gateway.ledger.spent_by_day(Some(&key.name), last_days),
        "apis_by_provider": gateway.apis_by_provider(),
        "models_by_provider": gateway.models_by_provider(),
    })))
}

async fn health() -> StatusCode {
    StatusCode::OK
}
