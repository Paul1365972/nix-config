_: {
  den.aspects.saber.provides.backup.nixos = {
    services.borgbackup.jobs.hdd = {
      repo = "/mnt/hdd/backup/saber";
      encryption.mode = "none";
      compression = "zstd";
      startAt = "*-*-* 03:30:00";
      paths = [
        "/var/lib/hass"
        "/var/lib/zigbee2mqtt"
        "/var/lib/maubot"
        "/var/lib/matrix-synapse"
        "/var/lib/nextcloud"
        "/var/lib/jellyfin"
        "/var/lib/private/traccar"
        "/var/backup/postgresql"
      ];
      exclude = [
        "/var/lib/matrix-synapse/media_store"
        "/var/lib/jellyfin/media"
        "/var/lib/jellyfin/transcodes"
      ];
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
    };

    systemd.services.borgbackup-job-hdd.unitConfig.RequiresMountsFor = [ "/mnt/hdd" ];
  };
}
