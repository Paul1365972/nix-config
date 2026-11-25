mod api;
mod config;
mod dashboard;
mod gateway;
mod http;
mod keys;
mod ledger;
mod meter;
mod price;
mod refusal;
mod report;
mod request;
mod store;
mod usage;

use std::{path::PathBuf, process::ExitCode, sync::Arc, time::Duration};

use anyhow::{Context, Result};
use clap::Parser;
use tokio::runtime::Runtime;

use crate::{config::Config, gateway::Gateway};

const RUNTIME_STOP_LIMIT: Duration = Duration::from_secs(5);

#[derive(Parser)]
#[command(
    version,
    about = "One gateway in front of several model providers, with a spending limit per key"
)]
struct Arguments {
    #[arg(long)]
    config: PathBuf,
}

fn main() -> ExitCode {
    tracing_subscriber::fmt()
        .with_writer(std::io::stdout)
        .with_ansi(false)
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();
    let _ = rustls::crypto::ring::default_provider().install_default();

    match run(&Arguments::parse()) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("llm-gateway: {error:#}");
            ExitCode::FAILURE
        }
    }
}

fn run(arguments: &Arguments) -> Result<()> {
    let config = Config::load(&arguments.config)?;
    let (listen, dashboard_listen) = (config.listen, config.dashboard_listen);
    let gateway = Arc::new(Gateway::new(config)?);
    let runtime = Runtime::new().context("starting the runtime")?;
    let served = runtime.block_on(http::serve(gateway.clone(), listen, dashboard_listen));
    charge_running_responses_by_dropping_them(runtime);
    gateway.store.flush();
    served
}

fn charge_running_responses_by_dropping_them(runtime: Runtime) {
    runtime.shutdown_timeout(RUNTIME_STOP_LIMIT);
}
