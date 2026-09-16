{
  den.aspects.saber.provides.backup.nixos =
    { config, pkgs, ... }:
    let
      units = config.systemd.services.borgbackup-job-hdd.conflicts;
    in
    {
      services.borgbackup.jobs.hdd = {
        repo = "/mnt/hdd/backup/saber";
        encryption.mode = "none";
        compression = "zstd";
        startAt = "*-*-* 03:30:00";
        preHook = "${pkgs.systemd}/bin/systemctl start postgresqlBackup.service";
        prune.keep = {
          daily = 7;
          weekly = 4;
          monthly = 6;
        };
      };
      systemd.services.borgbackup-job-hdd = {
        conflicts = [
          "comin.service"
          "auto-reboot.timer"
        ];
        after = units;
        onSuccess = units;
        onFailure = units;
        unitConfig.OnFailureJobMode = "fail";
      };
    };
}
