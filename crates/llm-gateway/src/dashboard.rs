use std::{collections::BTreeMap, sync::Arc};

use axum::{
    Json, Router,
    extract::{Path, Query, Request, State},
    http::{Method, StatusCode},
    middleware::{self, Next},
    response::Response,
    routing::{get, post, put},
};
use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use tokio::task::block_in_place;

use crate::{
    gateway::Gateway,
    keys::{KeyError, KeySettings},
    ledger::{Month, SpentByProvider, TalliesByKey, today},
    page,
    price::MicroUsd,
    refusal::Refusal,
};

pub fn router_without_login(gateway: Arc<Gateway>) -> Router {
    Router::new()
        .merge(page::dashboard_routes())
        .route("/api/overview", get(overview))
        .route("/api/keys", post(create_key))
        .route("/api/keys/{name}", put(update_key).delete(delete_key))
        .route("/api/keys/{name}/token", get(key_token))
        .route("/api/keys/{name}/revoke", post(revoke_key))
        .route("/api/keys/{name}/restore", post(restore_key))
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

#[derive(Deserialize)]
struct OverviewQuery {
    month: Option<String>,
}

#[derive(Serialize)]
struct Overview {
    public_url: String,
    month: String,
    months: Vec<String>,
    providers: Vec<String>,
    keys: Vec<KeyOverview>,
    tallies: TalliesByKey,
    today: NaiveDate,
    days: BTreeMap<NaiveDate, SpentByProvider>,
}

#[derive(Serialize)]
struct KeyOverview {
    name: Arc<str>,
    #[serde(flatten)]
    settings: KeySettings,
    running_requests: usize,
    is_revoked: bool,
    token_prefix: String,
    token_secret_length: usize,
    limit_resets_on: Option<NaiveDate>,
    spent_usd: MicroUsd,
    spent_usd_by_provider: SpentByProvider,
}

async fn overview(
    State(gateway): State<Arc<Gateway>>,
    Query(query): Query<OverviewQuery>,
) -> Result<Json<Overview>, Refusal> {
    let month = query.month.map(|month| month.parse::<Month>()).transpose();
    let month = month
        .map_err(|_| Refusal::invalid_request("invalid_month", "A month reads YYYY-MM."))?
        .unwrap_or_else(Month::now);
    let keys = gateway.keys.all().into_iter().map(|key| {
        let spent_usd_by_provider = gateway.spent_on_every_provider(&key);
        let (token_prefix, token_secret) = key.token_prefix_and_secret();
        KeyOverview {
            name: key.name.clone(),
            settings: key.settings.clone(),
            running_requests: key.running_requests(),
            is_revoked: key.is_revoked,
            token_prefix: token_prefix.to_owned(),
            token_secret_length: token_secret.len(),
            limit_resets_on: key.limit_resets_on(),
            spent_usd: spent_usd_by_provider.values().copied().sum(),
            spent_usd_by_provider,
        }
    });
    let months = gateway.ledger.months();
    Ok(Json(Overview {
        public_url: gateway.public_url.clone(),
        month: month.to_string(),
        months: months.iter().rev().map(Month::to_string).collect(),
        providers: gateway.providers().map(str::to_owned).collect(),
        keys: keys.collect(),
        tallies: gateway.ledger.month(month),
        today: today(),
        days: gateway.ledger.spent_by_day(None, month.days()),
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
    require_configured_providers(&gateway, &settings)?;
    let token = block_in_place(|| gateway.keys.create(&name, settings))?;
    tracing::info!(key = name, "created a key");
    Ok(Json(json!({ "token": token })))
}

async fn update_key(
    State(gateway): State<Arc<Gateway>>,
    Path(name): Path<String>,
    Json(settings): Json<KeySettings>,
) -> Result<StatusCode, Refusal> {
    require_configured_providers(&gateway, &settings)?;
    block_in_place(|| gateway.keys.update(&name, settings))?;
    tracing::info!(key = name, "updated a key");
    Ok(StatusCode::NO_CONTENT)
}

async fn key_token(
    State(gateway): State<Arc<Gateway>>,
    Path(name): Path<String>,
) -> Result<Json<Value>, Refusal> {
    let key = gateway.keys.named(&name).ok_or(KeyError::NotFound)?;
    Ok(Json(json!({ "token": key.token })))
}

async fn delete_key(
    State(gateway): State<Arc<Gateway>>,
    Path(name): Path<String>,
) -> Result<StatusCode, Refusal> {
    block_in_place(|| gateway.keys.delete(&name))?;
    tracing::info!(key = name, "deleted a key");
    Ok(StatusCode::NO_CONTENT)
}

async fn restore_key(
    State(gateway): State<Arc<Gateway>>,
    Path(name): Path<String>,
) -> Result<StatusCode, Refusal> {
    block_in_place(|| gateway.keys.restore(&name))?;
    tracing::info!(key = name, "restored a key");
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

fn require_configured_providers(gateway: &Gateway, settings: &KeySettings) -> Result<(), Refusal> {
    let is_configured = |name: &String| gateway.providers().any(|provider| provider == name);
    if settings.limit_usd_by_provider.keys().all(is_configured) {
        return Ok(());
    }
    Err(Refusal::invalid_request(
        "unknown_provider",
        "A key can only limit configured providers.",
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
