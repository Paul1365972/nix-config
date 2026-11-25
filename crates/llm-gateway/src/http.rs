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
    response::{IntoResponse, Response},
    routing::{get, post},
    serve::ListenerExt,
};
use chrono::Days;
use serde_json::{Value, json};
use tokio::{sync::oneshot, time::sleep};
use tokio_util::sync::CancellationToken;

use crate::{
    api::{
        Api, Endpoint, GenerateContentMethod, Work, X_API_KEY, X_GOOG_API_KEY,
        check_generate_content_query,
    },
    dashboard,
    gateway::{Gateway, Model, Provider},
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
        .merge(api_routes())
        .route("/v1/models", get(models_of_chat_completions))
        .route("/{provider}/v1/models", get(models_of_provider))
        .route("/v1/usage", get(usage))
        .route("/health", get(health))
        .fallback(no_route)
        .with_state(gateway.clone());
    let listener = bind(listen).await?;
    let dashboard_listener = bind(dashboard_listen).await?;
    tracing::info!(%listen, %dashboard_listen, "serving");

    let mut responses_running = gateway.responses_running.subscribe();
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
    let serving_and_reading_responses_to_their_end = async {
        let served = tokio::try_join!(serving, serving_dashboard);
        let _ = responses_running.wait_for(|running| *running == 0).await;
        served
    };
    tokio::select! {
        served = serving_and_reading_responses_to_their_end => {
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

fn api_routes() -> Router<Arc<Gateway>> {
    let mut routes = Router::new()
        .route("/{provider}/v1beta/models", get(generate_content_models))
        .route("/{provider}/v1beta/models/{target}", post(generate_content));
    for (api, work, path) in Api::ROUTES_WITH_MODEL_IN_BODY {
        routes = routes.route(
            &format!("/{{provider}}/v1{path}"),
            post(
                move |State(gateway), Path(provider): Path<String>, request| async move {
                    let endpoint = Endpoint::BodyModel {
                        api,
                        work,
                        path,
                        provider: Some(&provider),
                    };
                    forward(gateway, endpoint, request).await
                },
            ),
        );
        if work == Work::Answer {
            let endpoint = Endpoint::BodyModel {
                api,
                work,
                path,
                provider: None,
            };
            routes = routes.route(
                &format!("/v1{path}"),
                post(move |State(gateway), request| forward(gateway, endpoint, request)),
            );
        }
    }
    routes
}

async fn generate_content(
    State(gateway): State<Arc<Gateway>>,
    Path((provider, target)): Path<(String, String)>,
    request: Request,
) -> Result<Response, Refusal> {
    if let Some((model, method)) = target.split_once(':')
        && model.starts_with(|first: char| first.is_ascii_alphanumeric())
        && model
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || b"-_.".contains(&byte))
        && let Some(method) = GenerateContentMethod::named(method)
    {
        let endpoint = Endpoint::PathModel {
            provider: &provider,
            model,
            method,
        };
        return forward(gateway, endpoint, request).await;
    }
    Err(no_route(request).await)
}

async fn no_route(request: Request) -> Refusal {
    let route = format!("{} {}", request.method(), request.uri().path());
    let _ = to_bytes(request.into_body(), REQUEST_BODY_LIMIT_BYTES).await;
    Refusal::new(
        StatusCode::NOT_FOUND,
        "not_found_error",
        "no_route",
        format!("The gateway has no route {route}."),
    )
}

async fn forward(
    gateway: Arc<Gateway>,
    endpoint: Endpoint<'_>,
    request: Request,
) -> Result<Response, Refusal> {
    let key = authenticate(&gateway, request.headers())?;
    let answer = answer(gateway, key.clone(), endpoint, request).await;
    answer.inspect_err(|refusal| {
        let api = endpoint.api();
        tracing::info!(key = %key.name, ?api, %refusal, "refused a request");
    })
}

async fn answer(
    gateway: Arc<Gateway>,
    key: Arc<Key>,
    endpoint: Endpoint<'_>,
    request: Request,
) -> Result<Response, Refusal> {
    let (api, work) = (endpoint.api(), endpoint.work());
    let mut headers = api.headers_passed_on(request.headers())?;
    let query_of_url = match endpoint.query_to_forward(request.uri().query())? {
        "" => String::new(),
        query => format!("?{query}"),
    };
    let running_request = gateway.run_request(&key)?;
    let body = request.into_body();
    let body = to_bytes(body, REQUEST_BODY_LIMIT_BYTES).await.map_err(|_| {
        Refusal::invalid_request(
            "unreadable_body",
            format!("The request body could not be read; it may hold at most {REQUEST_BODY_LIMIT_BYTES} bytes."),
        )
    })?;
    let request = RequestBody::read(&body, api, work)?;
    let (model_name, model_name_carries_provider) = match endpoint {
        Endpoint::BodyModel { provider, .. } => (request.model_name(provider)?, provider.is_none()),
        Endpoint::PathModel {
            provider, model, ..
        } => (format!("{provider}/{model}"), false),
    };
    let model = gateway.model_served(&key, api, &model_name)?;
    let provider = model.provider.clone();
    let upstream_body = request.upstream_body(model_name_carries_provider, work);

    let url = format!(
        "{}{}{query_of_url}",
        provider.base_url(api),
        endpoint.path()
    );
    let (credential, value) = api.credentials(&provider);
    headers.insert(credential, value);
    headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));

    let sending = gateway
        .client
        .post(url)
        .headers(headers)
        .body(upstream_body);
    let meter = Meter::start(gateway, key, model, api, running_request);
    let meter = match work {
        Work::Answer => meter,
        Work::CountTokens => meter.unbilled(),
    };
    let (answer, answered) = oneshot::channel();
    tokio::spawn(exchange_outliving_the_client(
        sending, meter, provider, answer,
    ));
    answered.await.unwrap_or_else(|_| {
        Err(Refusal::new(
            StatusCode::BAD_GATEWAY,
            "api_error",
            "gateway_stopping",
            "The gateway is stopping.",
        ))
    })
}

async fn exchange_outliving_the_client(
    sending: reqwest::RequestBuilder,
    meter: Meter,
    provider: Arc<Provider>,
    answer: oneshot::Sender<Result<Response, Refusal>>,
) {
    let upstream = match sending.send().await {
        Ok(upstream) => upstream,
        Err(error) => {
            let never_reached_provider = error.is_connect();
            let error = error.without_url();
            tracing::warn!(provider = provider.name, %error, "the provider did not answer");
            if never_reached_provider {
                meter.leave_unbilled();
            }
            let _ = answer.send(Err(Refusal::new(
                StatusCode::BAD_GATEWAY,
                "api_error",
                "provider_unreachable",
                format!("The provider {} did not answer.", provider.name),
            )));
            return;
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
        let _ = answer.send(Err(Refusal::new(
            StatusCode::BAD_GATEWAY,
            "api_error",
            "provider_refused_gateway",
            format!("The provider {} refused the gateway.", provider.name),
        )));
        return;
    }

    let pass_on_body =
        status.is_success() || matches!(status.as_u16(), 400 | 404 | 409 | 413 | 422);
    let mut response = if pass_on_body {
        Response::new(Body::empty())
    } else {
        Refusal::new(
            status,
            "api_error",
            "provider_error",
            format!(
                "The provider {} answered {}.",
                provider.name,
                status.as_u16()
            ),
        )
        .body()
        .into_response()
    };
    *response.status_mut() = status;
    for name in FORWARDED_RESPONSE_HEADERS {
        if name == CONTENT_TYPE && !pass_on_body {
            continue;
        }
        for value in upstream.headers().get_all(&name) {
            response.headers_mut().append(name.clone(), value.clone());
        }
    }
    let is_billed_by_provider = status.is_success();
    if !is_billed_by_provider {
        meter.leave_unbilled();
        if pass_on_body {
            *response.body_mut() = Body::new(reqwest::Body::from(upstream));
        }
        let _ = answer.send(Ok(response));
        return;
    }
    let (body, reading_to_the_end) = relay(upstream, meter);
    *response.body_mut() = body;
    let _ = answer.send(Ok(response));
    reading_to_the_end.await;
}

fn authenticate(gateway: &Gateway, headers: &HeaderMap) -> Result<Arc<Key>, Refusal> {
    let header = |name| headers.get(name).and_then(|value| value.to_str().ok());
    let token_of_anthropic_client = header(X_API_KEY).filter(|token| !token.is_empty());
    let token_of_openai_client = header(AUTHORIZATION).and_then(|value| {
        let (scheme, token) = value.split_once(' ')?;
        scheme.eq_ignore_ascii_case("bearer").then_some(token)
    });
    let token_of_google_client = header(X_GOOG_API_KEY).filter(|token| !token.is_empty());
    let token = token_of_anthropic_client
        .or(token_of_openai_client)
        .or(token_of_google_client);
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

async fn models_of_chat_completions(
    State(gateway): State<Arc<Gateway>>,
    headers: HeaderMap,
) -> Result<Json<Value>, Refusal> {
    authenticate(&gateway, &headers)?;
    let served = |model: &&Model| model.provider.serves(Api::ChatCompletions);
    let models = gateway.models().filter(served);
    Ok(Json(listed(models.map(|model| (&*model.name, model)))))
}

async fn models_of_provider(
    State(gateway): State<Arc<Gateway>>,
    Path(provider): Path<String>,
    headers: HeaderMap,
) -> Result<Json<Value>, Refusal> {
    authenticate(&gateway, &headers)?;
    Ok(Json(listed(provider_models(&gateway, &provider))))
}

async fn generate_content_models(
    State(gateway): State<Arc<Gateway>>,
    Path(provider): Path<String>,
    request: Request,
) -> Result<Json<Value>, Refusal> {
    authenticate(&gateway, request.headers())?;
    if !gateway.provider_serves(&provider, Api::GenerateContent) {
        return Err(no_route(request).await);
    }
    check_generate_content_query(request.uri().query(), None)?;
    let models: Vec<_> = provider_models(&gateway, &provider)
        .map(|(name, _)| {
            json!({
                "name": format!("models/{name}"),
                "displayName": name,
                "supportedGenerationMethods": ["generateContent", "countTokens"],
            })
        })
        .collect();
    Ok(Json(json!({ "models": models })))
}

fn provider_models<'gateway>(
    gateway: &'gateway Gateway,
    provider: &str,
) -> impl Iterator<Item = (&'gateway str, &'gateway Model)> {
    gateway.models().filter_map(move |model| {
        let (model_provider, name_in_provider) = model.name.split_once('/')?;
        (model_provider == provider).then_some((name_in_provider, model))
    })
}

fn listed<'model>(models: impl Iterator<Item = (&'model str, &'model Model)>) -> Value {
    let models: Vec<Value> = models
        .map(|(name, model)| {
            let as_openai_clients_read_it =
                json!({ "id": name, "object": "model", "created": 0, "owned_by": model.provider.name });
            let as_anthropic_clients_read_it_too =
                json!({ "type": "model", "display_name": name, "created_at": "1970-01-01T00:00:00Z" });
            let mut model = as_openai_clients_read_it;
            model
                .as_object_mut()
                .into_iter()
                .zip(as_anthropic_clients_read_it_too.as_object())
                .for_each(|(model, more)| model.extend(more.clone()));
            model
        })
        .collect();
    let id = |model: Option<&Value>| model.map(|model| model["id"].clone());
    json!({
        "object": "list",
        "has_more": false,
        "first_id": id(models.first()),
        "last_id": id(models.last()),
        "data": models,
    })
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
