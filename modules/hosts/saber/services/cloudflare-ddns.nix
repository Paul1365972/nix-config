{ inputs, ... }:
{
  den.aspects.saber.provides.cloudflare-ddns = {
    nixos =
      { config, ... }:
      {
        services.cloudflare-dyndns = {
          enable = true;
          apiTokenFile = config.sops.secrets.cloudflare-ddns-token.path;
          domains = [ "1365972.xyz" ];
          ipv6 = true;
        };

        sops.secrets.cloudflare-ddns-token = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          mode = "0400";
        };
      };
  };
}
