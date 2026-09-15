{
  den.aspects.saber.provides.postgresql.nixos =
    { config, pkgs, ... }:
    {
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_17;
        identMap = ''
          saber root      all
          saber postgres  all
        '';
      };
      services.postgresqlBackup = {
        enable = true;
        location = "/var/backup/postgresql";
        startAt = [ ];
        compression = "zstd";
      };
      services.borgbackup.jobs.hdd.paths = [ config.services.postgresqlBackup.location ];
    };
}
