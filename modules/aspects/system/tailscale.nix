{ inputs, ... }:
{
  den.aspects.tailscale =
    { host, ... }:
    {
      nixos =
        { config, ... }:
        {
          services.tailscale = {
            enable = true;
            authKeyFile = config.sops.secrets.tailscale-authkey.path;
            extraUpFlags = [ "--ssh" ];
          };

          sops.secrets.tailscale-authkey.sopsFile = inputs.self + "/secrets/${host.name}.yaml";
        };
    };
}
