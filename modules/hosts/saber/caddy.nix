{ inputs, ... }:
let
  tunnel = "2a7c9fd6-e5c6-4e49-900e-9a7bac28f4ff";
in
{
  den.aspects.saber.provides.caddy.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      publicHostnames = lib.filter (name: !lib.hasPrefix ":" name) (
        lib.attrNames config.services.caddy.virtualHosts
      );
    in
    {
      sops.secrets.caddy-env = {
        sopsFile = inputs.self + "/secrets/saber.yaml";
        owner = "caddy";
        mode = "0440";
        restartUnits = [ "caddy.service" ];
      };
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
          hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
        };
        globalConfig = ''
          email me@paul.moe
          acme_dns cloudflare {env.CF_API_TOKEN}
          default_bind 127.0.0.1 [::1]
          servers {
            trusted_proxies static 127.0.0.1/32 ::1/128
            client_ip_headers Cf-Connecting-Ip
          }
        '';
      };
      systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.caddy-env.path;

      sops.secrets.cloudflared-credentials = {
        sopsFile = inputs.self + "/secrets/saber.yaml";
        restartUnits = [ "cloudflared-tunnel-${tunnel}.service" ];
      };
      services.cloudflared = {
        enable = true;
        tunnels.${tunnel} = {
          credentialsFile = config.sops.secrets.cloudflared-credentials.path;
          ingress = lib.genAttrs publicHostnames (hostname: {
            service = "https://127.0.0.1:443";
            originRequest.originServerName = hostname;
          });
          default = "http_status:404";
        };
      };
    };
}
