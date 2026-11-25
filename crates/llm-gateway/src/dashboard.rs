use std::sync::Arc;

use axum::{
    Json, Router,
    extract::{Path, Query, Request, State},
    http::{
        Method, StatusCode,
        header::{CACHE_CONTROL, CONTENT_SECURITY_POLICY, CONTENT_TYPE, X_FRAME_OPTIONS},
    },
    middleware::{self, Next},
    response::{Html, IntoResponse, Response},
    routing::{get, post, put},
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use tokio::task::block_in_place;

use crate::{
    gateway::Gateway,
    keys::{KeyError, KeySettings},
    ledger::{Month, Tallies},
    refusal::Refusal,
};

pub fn router_without_login(gateway: Arc<Gateway>) -> Router {
    Router::new()
        .route("/", get(page))
        .route("/m-plus-2.woff2", get(font))
        .route("/api/overview", get(overview))
        .route("/api/keys", post(create_key))
        .route("/api/keys/{name}", put(update_key).delete(revoke_key))
        .layer(middleware::from_fn(refuse_changes_from_other_sites))
        .with_state(gateway)
}

async fn refuse_changes_from_other_sites(
    request: Request,
    next: Next,
) -> Result<Response, Refusal> {
    let fetch_site = request.headers().get("sec-fetch-site");
    let is_from_other_site = fetch_site.is_some_and(|site| site != "same-origin" && site != "none");
    let is_change = request.method() != Method::GET;
    if is_change && is_from_other_site {
        return Err(Refusal::new(
            StatusCode::FORBIDDEN,
            "permission_error",
            "cross_site_request",
            "Only the dashboard itself may change keys.",
        ));
    }
    Ok(next.run(request).await)
}

async fn page() -> impl IntoResponse {
    let no_other_site_may_frame_it = [
        (CONTENT_SECURITY_POLICY, "frame-ancestors 'none'"),
        (X_FRAME_OPTIONS, "DENY"),
    ];
    (
        no_other_site_may_frame_it,
        Html(include_str!("../assets/dashboard.html")),
    )
}

async fn font() -> impl IntoResponse {
    let kept_by_the_browser = [
        (CONTENT_TYPE, "font/woff2"),
        (CACHE_CONTROL, "public, max-age=31536000, immutable"),
    ];
    (
        kept_by_the_browser,
        include_bytes!("../assets/m-plus-2.woff2").as_slice(),
    )
}

#[derive(Deserialize)]
struct OverviewQuery {
    month: Option<String>,
}

#[derive(Serialize)]
struct Overview {
    month: String,
    months: Vec<String>,
    providers: Vec<String>,
    models: Vec<Arc<str>>,
    keys: Vec<KeyOverview>,
    tallies: Tallies,
}

#[derive(Serialize)]
struct KeyOverview {
    name: Arc<str>,
    #[serde(flatten)]
    settings: KeySettings,
    running_requests: usize,
}

async fn overview(
    State(gateway): State<Arc<Gateway>>,
    Query(query): Query<OverviewQuery>,
) -> Result<Json<Overview>, Refusal> {
    let month = query.month.map(|month| month.parse::<Month>()).transpose();
    let month = month
        .map_err(|_| Refusal::invalid_request("invalid_month", "A month reads YYYY-MM."))?
        .unwrap_or(gateway.ledger.this_month().0);
    let unreadable = |error: anyhow::Error| {
        tracing::error!(%error, "the store was not read");
        Refusal::new(
            StatusCode::SERVICE_UNAVAILABLE,
            "api_error",
            "store_unreadable",
            "The store could not be read.",
        )
    };
    let tallies = block_in_place(|| gateway.ledger.month(month)).map_err(unreadable)?;
    let months = block_in_place(|| gateway.ledger.months()).map_err(unreadable)?;
    let keys = gateway.keys.all().into_iter().map(|key| KeyOverview {
        name: key.name.clone(),
        settings: key.settings.clone(),
        running_requests: key.running_requests(),
    });
    Ok(Json(Overview {
        month: month.to_string(),
        months: months.iter().rev().map(Month::to_string).collect(),
        providers: gateway.providers().map(str::to_owned).collect(),
        models: gateway.models().map(|model| model.name.clone()).collect(),
        keys: keys.collect(),
        tallies,
    }))
}

#[derive(Deserialize)]
struct NewKey {
    name: String,
    #[serde(flatten)]
    settings: KeySettings,
}

async fn create_key(
    State(gateway): State<Arc<Gateway>>,
    Json(NewKey { name, settings }): Json<NewKey>,
) -> Result<Json<Value>, Refusal> {
    require_configured_providers_and_models(&gateway, &settings)?;
    let token = block_in_place(|| gateway.keys.create(&name, settings))?;
    tracing::info!(key = name, "created a key");
    Ok(Json(json!({ "token": token })))
}

async fn update_key(
    State(gateway): State<Arc<Gateway>>,
    Path(name): Path<String>,
    Json(settings): Json<KeySettings>,
) -> Result<StatusCode, Refusal> {
    require_configured_providers_and_models(&gateway, &settings)?;
    block_in_place(|| gateway.keys.update(&name, settings))?;
    tracing::info!(key = name, "updated a key");
    Ok(StatusCode::NO_CONTENT)
}

async fn revoke_key(
    State(gateway): State<Arc<Gateway>>,
    Path(name): Path<String>,
) -> Result<StatusCode, Refusal> {
    block_in_place(|| gateway.keys.revoke(&name))?;
    tracing::info!(key = name, "revoked a key");
    Ok(StatusCode::NO_CONTENT)
}

fn require_configured_providers_and_models(
    gateway: &Gateway,
    settings: &KeySettings,
) -> Result<(), Refusal> {
    let is_provider = |name: &String| gateway.providers().any(|provider| provider == name);
    let is_model = |name: &String| gateway.models().any(|model| *model.name == **name);
    let providers_are_configured = settings.only_providers.iter().flatten().all(is_provider);
    let models_are_configured = settings.limit_usd_per_month_by_model.keys().all(is_model);
    if providers_are_configured && models_are_configured {
        return Ok(());
    }
    Err(Refusal::invalid_request(
        "unknown_provider_or_model",
        "A key can only name configured providers and models.",
    ))
}

impl From<KeyError> for Refusal {
    fn from(error: KeyError) -> Self {
        let (status, kind, code) = match error {
            KeyError::InvalidName => (
                StatusCode::BAD_REQUEST,
                "invalid_request_error",
                "invalid_name",
            ),
            KeyError::InvalidSettings => (
                StatusCode::BAD_REQUEST,
                "invalid_request_error",
                "invalid_settings",
            ),
            KeyError::NameTaken => (StatusCode::CONFLICT, "invalid_request_error", "name_taken"),
            KeyError::NotFound => (StatusCode::NOT_FOUND, "not_found_error", "key_not_found"),
        };
        Self::new(status, kind, code, error.to_string())
    }
}
