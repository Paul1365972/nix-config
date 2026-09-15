_: {
  den.aspects.saber.provides.jellyfin = {
    nixos = {
      services.jellyfin.enable = true;
      users.users.jellyfin.extraGroups = [ "render" ];
      services.caddy.virtualHosts."jellyfin.1365972.xyz".extraConfig = ''
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
      saber.backup.units = [ "jellyfin.service" ];
      saber.dashboard.Jellyfin = {
        description = "Media";
        href = "https://jellyfin.1365972.xyz";
        icon = "jellyfin.svg";
      };
    };
  };
}
