{ inputs, ... }:
let
  tunnel = "2a7c9fd6-e5c6-4e49-900e-9a7bac28f4ff";
in
{
  den.aspects.saber.provides.caddy.nixos =
    { config, lib, ... }:
    let
      publicHostnames = map (lib.removePrefix "http://") (
        lib.filter (lib.hasPrefix "http://") (lib.attrNames config.services.caddy.virtualHosts)
      );
    in
    {
      services.caddy = {
        enable = true;
        globalConfig = ''
          default_bind 127.0.0.1 [::1]
          servers {
            trusted_proxies static 127.0.0.1/32 ::1/128
            client_ip_headers Cf-Connecting-Ip
          }
        '';
      };

      sops.secrets.cloudflared-credentials = {
        sopsFile = inputs.self + "/secrets/saber.yaml";
        restartUnits = [ "cloudflared-tunnel-${tunnel}.service" ];
      };
      services.cloudflared = {
        enable = true;
        tunnels.${tunnel} = {
          credentialsFile = config.sops.secrets.cloudflared-credentials.path;
          ingress = lib.genAttrs publicHostnames (_: "http://127.0.0.1:80");
          default = "http_status:404";
        };
      };
    };
}
