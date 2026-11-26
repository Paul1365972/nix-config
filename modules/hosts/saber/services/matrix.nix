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
          "http://matrix.paul.moe".extraConfig = ''
            handle /.well-known/matrix/client {
              header Content-Type application/json
              header Access-Control-Allow-Origin *
              respond `{"m.homeserver":{"base_url":"https://matrix.paul.moe"}}`
            }
            @servedOnlyInTheTailnetOrNowhere path /_synapse/admin/* /_matrix/federation/* /_matrix/key/*
            handle @servedOnlyInTheTailnetOrNowhere {
              respond 404
            }
            handle {
              reverse_proxy http://127.0.0.1:8008 {
                header_up X-Forwarded-For {client_ip}
              }
            }
          '';
          ":8091".extraConfig = ''
            bind 127.0.0.1
            @synapse path /_matrix/* /_synapse/*
            handle @synapse {
              reverse_proxy http://127.0.0.1:8008
            }
            handle /config.json {
              header Content-Type application/json
              respond `{"restrictBaseUrl":"https://matrix-admin.echidna-ghost.ts.net"}`
            }
            handle {
              root * ${pkgs.synapse-admin}
              file_server
              try_files {path} /index.html
            }
          '';
        };
        services.tailscale.serve.services.matrix-admin.endpoints."tcp:443" = "http://127.0.0.1:8091";
        fileSystems."/var/lib/matrix-synapse/media_store" = {
          device = "/mnt/hdd/matrix-media";
          fsType = "none";
          options = [ "bind" ];
          depends = [ "/mnt/hdd" ];
        };
        services.homepage-dashboard.entries."Synapse Admin" = {
          description = "Matrix admin UI";
          href = "https://matrix-admin.echidna-ghost.ts.net";
          icon = "matrix.svg";
        };
        services.matrix-synapse = {
          enable = true;

          settings = {
            # User IDs are @paul:matrix.paul.moe, not @paul:paul.moe; changing this invalidates every account and federated device.
            server_name = "matrix.paul.moe";
            public_baseurl = "https://matrix.paul.moe/";

            database = {
              name = "psycopg2";
              args = {
                user = "synapse";
                database = "synapse";
                host = "/run/postgresql";
              };
            };

            registration_requires_token = true;
            require_auth_for_profile_requests = true;
            federation_domain_whitelist = [ ];
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
