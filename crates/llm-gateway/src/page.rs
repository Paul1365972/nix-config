use axum::{
    Router,
    http::header::{
        CACHE_CONTROL, CONTENT_SECURITY_POLICY, CONTENT_TYPE, REFERRER_POLICY, X_FRAME_OPTIONS,
    },
    response::{Html, IntoResponse},
    routing::get,
};

const ONLY_ITS_OWN_FILES_AND_ORIGIN: &str = "default-src 'none'; style-src 'self' 'unsafe-inline'; script-src 'self'; font-src 'self'; img-src 'self'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'";
const JAVASCRIPT: &str = "text/javascript; charset=utf-8";

pub fn usage_routes<S: Clone + Send + Sync + 'static>() -> Router<S> {
    let scripts = [
        ("/usage.js", include_str!("../assets/usage.js")),
        ("/setup.js", include_str!("../assets/setup.js")),
    ];
    routes(include_str!("../assets/usage.html"), scripts)
}

pub fn dashboard_routes<S: Clone + Send + Sync + 'static>() -> Router<S> {
    let scripts = [("/dashboard.js", include_str!("../assets/dashboard.js"))];
    routes(include_str!("../assets/dashboard.html"), scripts)
}

fn routes<S: Clone + Send + Sync + 'static>(
    html: &'static str,
    scripts: impl IntoIterator<Item = (&'static str, &'static str)>,
) -> Router<S> {
    let shared_scripts = [
        ("/shared.js", include_str!("../assets/shared.js")),
        ("/theme.js", include_str!("../assets/theme.js")),
    ];
    let shared_styles = include_str!("../assets/shared.css");
    let icon = include_str!("../assets/icon.svg");
    let router = Router::new()
        .route("/", get(async move || page(html)))
        .route(
            "/shared.css",
            get(async || file("text/css; charset=utf-8", shared_styles)),
        )
        .route("/icon.svg", get(async || file("image/svg+xml", icon)))
        .route("/m-plus-2.woff2", get(font));
    let scripts = scripts.into_iter().chain(shared_scripts);
    scripts.fold(router, |router, (path, script)| {
        router.route(path, get(async move || file(JAVASCRIPT, script)))
    })
}

fn page(html: &'static str) -> impl IntoResponse {
    let headers = [
        (CONTENT_SECURITY_POLICY, ONLY_ITS_OWN_FILES_AND_ORIGIN),
        (X_FRAME_OPTIONS, "DENY"),
        (REFERRER_POLICY, "no-referrer"),
        (CACHE_CONTROL, "no-cache"),
    ];
    (headers, Html(html))
}

fn file(content_type: &'static str, text: &'static str) -> impl IntoResponse {
    let asked_again_on_every_visit = [(CONTENT_TYPE, content_type), (CACHE_CONTROL, "no-cache")];
    (asked_again_on_every_visit, text)
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
