{ inputs, ... }:
{
  den.aspects.saber.provides.traccar = {
    nixos =
      { config, ... }:
      {
        services.traccar = {
          enable = true;
          environmentFile = config.sops.secrets.traccar-env.path;
          settings = {
            database = {
              driver = "org.postgresql.Driver";
              url = "jdbc:postgresql://localhost:5432/traccar";
              user = "traccar";
              password = "$DB_PASSWORD";
            };
            web = {
              address = "127.0.0.1";
              port = "8082";
              origin = "https://traccar.echidna-ghost.ts.net";
            };
          };
        };

        services.tailscale.serve.services.traccar.endpoints."tcp:443" = "http://127.0.0.1:8082";

        # services.traccar uses DynamicUser; route env access via the keys group.
        systemd.services.traccar.serviceConfig.SupplementaryGroups = [ "keys" ];
        sops.secrets.traccar-env = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          group = "keys";
          mode = "0440";
          restartUnits = [ "traccar.service" ];
        };
      };
  };
}
