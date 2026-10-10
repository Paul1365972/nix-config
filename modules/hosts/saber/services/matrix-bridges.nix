_: {
  den.aspects.saber.provides.matrix-bridges = {
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        serverName = config.services.matrix-synapse.settings.server_name;
        bridgeSettings = database: {
          homeserver.address = "http://127.0.0.1:8008";
          database = {
            type = "postgres";
            uri = "postgresql:///${database}?host=/run/postgresql&user=${database}";
          };
          bridge.permissions = {
            ${serverName} = "user";
            "@paul:${serverName}" = "admin";
          };
          backfill.enabled = true;
        };
      in
      {
        systemd.services.borgbackup-job-hdd.conflicts = [
          "mautrix-signal.service"
          "mautrix-whatsapp.service"
        ];
        services.postgresql = {
          ensureDatabases = [
            "mautrixsignal"
            "mautrixwhatsapp"
          ];
          ensureUsers = [
            {
              name = "mautrixsignal";
              ensureDBOwnership = true;
            }
            {
              name = "mautrixwhatsapp";
              ensureDBOwnership = true;
            }
          ];
          identMap = ''
            saber mautrix-signal    mautrixsignal
            saber mautrix-whatsapp  mautrixwhatsapp
          '';
          authentication = lib.mkAfter ''
            local mautrixsignal     mautrixsignal     peer map=saber
            local mautrixwhatsapp   mautrixwhatsapp   peer map=saber
          '';
        };

        services.mautrix-signal = {
          package = pkgs.mautrix-signal.override { withGoolm = true; };
          enable = true;
          registerToSynapse = true;
          settings = bridgeSettings "mautrixsignal";
        };

        services.mautrix-whatsapp = {
          package = pkgs.mautrix-whatsapp.override { withGoolm = true; };
          enable = true;
          registerToSynapse = true;
          settings = bridgeSettings "mautrixwhatsapp";
        };
      };
  };
}
