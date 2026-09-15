{ inputs, ... }:
{
  den.aspects.saber.provides.matrix = {
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        services.postgresql = {
          ensureDatabases = [ "synapse" ];
          ensureUsers = [
            {
              name = "synapse";
              ensureDBOwnership = true;
            }
          ];
          identMap = ''
            saber matrix-synapse synapse
          '';
          authentication = lib.mkAfter ''
            local synapse synapse peer map=saber
          '';
        };
        services.caddy.virtualHosts = {
          # Federation needs explicit delegation to 443 because server_name has no port.
          "matrix.1365972.xyz".extraConfig = ''
            handle /.well-known/matrix/server {
              header Content-Type application/json
              respond `{"m.server":"matrix.1365972.xyz:443"}`
            }
            handle /.well-known/matrix/client {
              header Content-Type application/json
              header Access-Control-Allow-Origin *
              respond `{"m.homeserver":{"base_url":"https://matrix.1365972.xyz"}}`
            }
            handle {
              reverse_proxy http://127.0.0.1:8008
            }
          '';
          ":8091".extraConfig = ''
            bind 127.0.0.1
            root * ${pkgs.synapse-admin}
            file_server
            try_files {path} /index.html
          '';
        };
        services.tailscale.serve.services.matrix-admin.endpoints."tcp:443" = "http://127.0.0.1:8091";
        fileSystems."/var/lib/matrix-synapse/media_store" = {
          device = "/mnt/hdd/matrix-media";
          fsType = "none";
          options = [ "bind" ];
          depends = [ "/mnt/hdd" ];
        };
        services.borgbackup.jobs.hdd = {
          paths = [ "/var/lib/matrix-synapse" ];
          exclude = [ "/var/lib/matrix-synapse/media_store" ];
        };
        saber.backup.units = [ "matrix-synapse.service" ];
        saber.dashboard."Synapse Admin" = {
          description = "Matrix admin UI";
          href = "https://matrix-admin.echidna-ghost.ts.net";
          icon = "matrix.svg";
        };
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

          extraConfigFiles = [ config.sops.secrets.synapse-secrets.path ];
        };

        systemd.services.matrix-synapse = {
          requires = [ "postgresql.target" ];
          after = [ "postgresql.target" ];
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
