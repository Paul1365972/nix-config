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
              port = "8082";
              origin = "https://traccar.1365972.xyz";
            };
            openid = {
              clientId = "yIsUke6CGrp73skB1lKeOPcyain6iFYQyfGJbeeB";
              clientSecret = "$OPENID_CLIENT_SECRET";
              issuerUrl = "https://authentik.1365972.xyz/application/o/traccar/";
              force = "false";
              allowGroup = "traccar";
              adminGroup = "traccar_admins";
            };
          };
        };

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
