{ inputs, ... }:
let
  tunnel = "2a7c9fd6-e5c6-4e49-900e-9a7bac28f4ff";
in
{
  den.aspects.saber.provides.cloudflared.nixos =
    { config, lib, ... }:
    {
      options.services.cloudflared.publicHosts = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Public hostnames and the local addresses the tunnel carries them to.";
      };
      config = {
        sops.secrets.cloudflared-credentials = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          restartUnits = [ "cloudflared-tunnel-${tunnel}.service" ];
        };
        services.cloudflared = {
          enable = true;
          tunnels.${tunnel} = {
            credentialsFile = config.sops.secrets.cloudflared-credentials.path;
            ingress = config.services.cloudflared.publicHosts;
            default = "http_status:404";
          };
        };
      };
    };
}
