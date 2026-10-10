_: {
  den.aspects.saber.provides.jellyfin = {
    nixos = {
      services.jellyfin.enable = true;
      users.users.jellyfin.extraGroups = [ "render" ];
      services.caddy.virtualHosts."jellyfin.paul.moe".extraConfig = ''
        reverse_proxy 127.0.0.1:8096
      '';
      fileSystems."/var/lib/jellyfin/media" = {
        device = "/mnt/hdd/media";
        fsType = "none";
        options = [ "bind" ];
        depends = [ "/mnt/hdd" ];
      };
      services.borgbackup.jobs.hdd = {
        paths = [ "/var/lib/jellyfin" ];
        exclude = [
          "/var/lib/jellyfin/media"
          "/var/lib/jellyfin/transcodes"
        ];
      };
      services.homepage-dashboard.entries.Jellyfin = {
        description = "Media";
        href = "https://jellyfin.paul.moe";
        icon = "jellyfin.svg";
      };
      systemd.services.borgbackup-job-hdd.conflicts = [ "jellyfin.service" ];
    };
  };
}
