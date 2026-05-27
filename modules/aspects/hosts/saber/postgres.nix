{ ... }:
{
  den.aspects.saber.provides.postgres = {
    nixos =
      { pkgs, lib, ... }:
      let
        services = [
          "authentik"
          "synapse"
          "traccar"
          "mautrixsignal"
          "mautrixwhatsapp"
          "maubot"
          "nextcloud"
        ];
      in
      {
        # Pinned to 14; major-version upgrades require a manual pg_upgrade step.
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
            saber mautrix-signal    mautrixsignal
            saber mautrix-whatsapp  mautrixwhatsapp
            saber root              all
            saber postgres          all
          '';

          authentication = lib.mkAfter ''
            local synapse           synapse           peer map=saber
            local mautrixsignal     mautrixsignal     peer map=saber
            local mautrixwhatsapp   mautrixwhatsapp   peer map=saber
          '';
        };

        # Daily pg_dumpall; picked up by restic in backups.nix.
        services.postgresqlBackup = {
          enable = true;
          location = "/var/backup/postgresql";
          startAt = "*-*-* 02:30:00";
          compression = "zstd";
        };
      };
  };
}
