{ inputs, ... }:
{
  den.aspects.saber.provides.caddy.nixos =
    { config, pkgs, ... }:
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
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
          hash = "sha256-F7d4HwM4oCkQrFMr4SFSC0r52ONxY+PW6z5BJawW8Ok=";
        };
        globalConfig = ''
          email paul@1365972.xyz
          acme_dns cloudflare {env.CF_API_TOKEN}
        '';
      };
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      networking.firewall.allowedUDPPorts = [ 443 ];
      systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.caddy-env.path;
    };
}
