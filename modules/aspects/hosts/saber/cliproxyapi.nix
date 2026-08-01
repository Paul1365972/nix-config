{ inputs, ... }:
{
  flake-file.inputs.llm-agents.url = "github:numtide/llm-agents.nix";

  den.aspects.saber.provides.cliproxyapi = {
    nixos =
      { config, pkgs, ... }:
      {
        nix.settings = {
          extra-substituters = [ "https://cache.numtide.com" ];
          extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
        };

        sops.secrets.cliproxyapi-api-key.sopsFile = inputs.self + "/secrets/saber.yaml";
        sops.secrets.cliproxyapi-management-key.sopsFile = inputs.self + "/secrets/saber.yaml";

        sops.templates."cliproxyapi.yaml" = {
          group = "keys";
          mode = "0440";
          restartUnits = [ "cliproxyapi.service" ];
          content = ''
            host: ""
            port: 8317
            auth-dir: "/var/lib/cliproxyapi/auth"
            api-keys:
              - "${config.sops.placeholder.cliproxyapi-api-key}"
            remote-management:
              allow-remote: true
              secret-key: "${config.sops.placeholder.cliproxyapi-management-key}"
              disable-auto-update-panel: true
            usage-statistics-enabled: true
            request-log: true
            logging-to-file: true
            logs-max-total-size-mb: 16384
          '';
        };

        systemd.services.cliproxyapi = {
          description = "CLIProxyAPI (Claude/OpenAI subscription proxy)";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          # default panel location is next to the (read-only) config file
          environment.MANAGEMENT_STATIC_PATH = "/var/lib/cliproxyapi/static";
          serviceConfig = {
            ExecStart = "${
              inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.cli-proxy-api
            }/bin/cli-proxy-api --config ${config.sops.templates."cliproxyapi.yaml".path}";
            DynamicUser = true;
            StateDirectory = "cliproxyapi";
            StateDirectoryMode = "0700";
            UMask = "0077";
            WorkingDirectory = "/var/lib/cliproxyapi";
            SupplementaryGroups = [ "keys" ];
            Restart = "on-failure";
            RestartSec = 5;
          };
        };

        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8317 ];
      };
  };
}
