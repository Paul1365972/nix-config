{ inputs, lib, ... }:
let
  listen = "127.0.0.1:8090";
  dashboardListen = "127.0.0.1:8092";
  publicHost = "llm.paul.moe";

  providers = {
    anthropic.base_urls = {
      messages = "https://api.anthropic.com/v1";
    };
    openai.base_urls = {
      responses = "https://api.openai.com/v1";
      chat_completions = "https://api.openai.com/v1";
    };
    google.base_urls = {
      chat_completions = "https://generativelanguage.googleapis.com/v1beta/openai";
      generate_content = "https://generativelanguage.googleapis.com/v1beta";
    };
  };

  models = lib.genAttrs [
    "anthropic/claude-haiku-5-5"
    "anthropic/claude-sonnet-5-5"
    "anthropic/claude-opus-5-5"
    "anthropic/claude-fable-5-2"
    "openai/gpt-6-luna"
    "openai/gpt-6.1-terra"
    "openai/gpt-6.2-sol"
    "openai/gpt-6.2-astra"
    "google/gemini-3.5-flash-lite"
    "google/gemini-flash-lite-latest"
    "google/gemini-4-hydrogen"
    "google/gemini-4-neon"
  ] pricesFromModelsDev;

  pricesFromModelsDev =
    name:
    let
      file = "providers/${builtins.replaceStrings [ "/" ] [ "/models/" ] name}.toml";
      inherit (builtins.fromTOML (builtins.readFile "${inputs.models-dev}/${file}")) cost;
      inherit (cost.text) input output;
      tokenPrices =
        input: output:
        {
          input_usd_per_million_tokens = input.price;
          output_usd_per_million_tokens = output.price;
        }
        // lib.optionalAttrs (input ? cache.read) { cache_read_usd_per_million_tokens = input.cache.read; }
        // lib.optionalAttrs (input ? cache.write) {
          cache_write_usd_per_million_tokens = input.cache.write;
        };
      longInput = lib.head input.overrides;
      longOutput = lib.head output.overrides;
    in
    {
      standard = tokenPrices input output;
    }
    // lib.optionalAttrs (input ? overrides) {
      long_context = {
        above_input_tokens = longInput.when.context.gt;
        prices = tokenPrices (lib.recursiveUpdate input longInput) (lib.recursiveUpdate output longOutput);
      };
    }
    // lib.optionalAttrs (cost ? web_search) { web_search_usd_per_thousand = cost.web_search.price; };
in
{
  flake-file.inputs.models-dev = {
    url = "github:anomalyco/models.dev";
    flake = false;
  };

  den.aspects.saber.provides.llm-gateway.nixos =
    { config, pkgs, ... }:
    let
      package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.llm-gateway;
      secret = provider: "llm-gateway-provider-${provider}";
      configFile = (pkgs.formats.toml { }).generate "llm-gateway.toml" {
        inherit listen models;
        dashboard_listen = dashboardListen;
        public_host = publicHost;
        store_file = "/var/lib/llm-gateway/store.redb";
        providers = lib.mapAttrs (
          name: provider: provider // { key_file = "/run/credentials/llm-gateway.service/${name}"; }
        ) providers;
      };
    in
    {
      sops.secrets = lib.mapAttrs' (
        name: _:
        lib.nameValuePair (secret name) {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          restartUnits = [ "llm-gateway.service" ];
        }
      ) providers;

      services.cloudflared.publicHosts.${publicHost} = "http://${listen}";
      services.tailscale.serve.services.llm-gateway.endpoints."tcp:443" = "http://${dashboardListen}";
      services.homepage-dashboard.entries."LLM Gateway" = {
        description = "Keys and spending";
        href = "https://llm-gateway.echidna-ghost.ts.net";
        icon = "mdi-key-chain-variant";
      };

      systemd.services.llm-gateway = {
        description = "One gateway in front of several model providers";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe package} --config ${configFile}";
          DynamicUser = true;
          StateDirectory = "llm-gateway";
          LoadCredential = lib.mapAttrsToList (
            name: _: "${name}:${config.sops.secrets.${secret name}.path}"
          ) providers;
          Restart = "always";
        };
      };
    };
}
