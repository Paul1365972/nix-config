{ ... }:
{
  den.aspects.saber.provides.postgres = {
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        services = [
          "authentik"
          "synapse"
          "traccar"
          "maubot"
          "nextcloud"
        ];
        # flip package to this after running upgrade-pg-cluster
        newPostgres = pkgs.postgresql_17;
        cfg = config.services.postgresql;
      in
      {
        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_14;

          ensureDatabases = services;
          ensureUsers = map (name: {
            inherit name;
            ensureDBOwnership = true;
          }) services;

          # Map OS service users whose names don't match their DB role onto the right role for peer auth.
          identMap = ''
            saber matrix-synapse    synapse
            saber root              all
            saber postgres          all
          '';

          authentication = lib.mkAfter ''
            local synapse           synapse           peer map=saber
          '';
        };

        services.postgresqlBackup = {
          enable = true;
          location = "/var/backup/postgresql";
          startAt = "*-*-* 02:30:00";
          compression = "zstd";
        };

        environment.systemPackages = [
          (pkgs.writeShellScriptBin "upgrade-pg-cluster" ''
            set -eux
            systemctl stop matrix-synapse maubot traccar phpfpm-nextcloud authentik authentik-worker || true
            systemctl stop postgresql

            export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
            export NEWBIN="${newPostgres}/bin"
            export OLDDATA="${cfg.dataDir}"
            export OLDBIN="${cfg.finalPackage}/bin"

            install -d -m 0700 -o postgres -g postgres "$NEWDATA"
            cd "$NEWDATA"
            sudo -u postgres "$NEWBIN/initdb" -D "$NEWDATA" ${lib.escapeShellArgs cfg.initdbArgs}

            sudo -u postgres "$NEWBIN/pg_upgrade" \
              --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
              --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
              "$@"
          '')
        ];
      };
  };
}
