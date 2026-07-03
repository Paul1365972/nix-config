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
          "maubot"
          "nextcloud"
        ];
      in
      {
        services.postgresql = {
          enable = true;
          # Pinned; major-version bumps need a manual pg_upgrade (see NixOS manual).
          package = pkgs.postgresql_17;

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
      };
  };
}
