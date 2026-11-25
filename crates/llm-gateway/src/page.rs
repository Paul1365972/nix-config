use axum::{
    http::header::{
        CACHE_CONTROL, CONTENT_SECURITY_POLICY, CONTENT_TYPE, REFERRER_POLICY, X_FRAME_OPTIONS,
    },
    response::{Html, IntoResponse},
};

const ONLY_ITS_OWN_INLINE_CODE_AND_ORIGIN: &str = "default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; font-src 'self'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'";

pub fn page(html: &'static str) -> impl IntoResponse {
    let headers = [
        (CONTENT_SECURITY_POLICY, ONLY_ITS_OWN_INLINE_CODE_AND_ORIGIN),
        (X_FRAME_OPTIONS, "DENY"),
        (REFERRER_POLICY, "no-referrer"),
    ];
    (headers, Html(html))
}

pub async fn font() -> impl IntoResponse {
    let kept_by_the_browser = [
        (CONTENT_TYPE, "font/woff2"),
        (CACHE_CONTROL, "public, max-age=31536000, immutable"),
    ];
    (
        kept_by_the_browser,
        include_bytes!("../assets/m-plus-2.woff2").as_slice(),
    )
}
