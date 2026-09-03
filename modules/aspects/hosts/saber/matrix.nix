{ inputs, ... }:
{
  den.aspects.saber.provides.matrix = {
    nixos =
      { config, ... }:
      {
        services.matrix-synapse = {
          enable = true;

          settings = {
            # User IDs are @paul:matrix.1365972.xyz, not @paul:1365972.xyz; changing this invalidates every account and federated device.
            server_name = "matrix.1365972.xyz";
            public_baseurl = "https://matrix.1365972.xyz/";

            database = {
              name = "psycopg2";
              args = {
                user = "synapse";
                database = "synapse";
                host = "/run/postgresql";
              };
            };

            registration_requires_token = true;
            password_config.enabled = true;
            suppress_key_server_warning = true;
          };

          # registration_shared_secret / macaroon_secret_key / form_secret come from saber.yaml.
          extraConfigFiles = [ config.sops.secrets.synapse-secrets.path ];
        };

        sops.secrets.synapse-secrets = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          owner = "matrix-synapse";
          mode = "0440";
          restartUnits = [ "matrix-synapse.service" ];
        };
      };
  };
}
