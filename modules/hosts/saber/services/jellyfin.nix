_: {
  den.aspects.saber.provides.jellyfin = {
    nixos = {
      services.jellyfin.enable = true;
      users.users.jellyfin.extraGroups = [ "render" ];
      services.tailscale.serve.services.jellyfin.endpoints."tcp:443" = "http://127.0.0.1:8096";
      fileSystems."/var/lib/jellyfin/media" = {
        device = "/mnt/hdd/media";
        fsType = "none";
        options = [ "bind" ];
        depends = [ "/mnt/hdd" ];
      };
      services.homepage-dashboard.entries.Jellyfin = {
        description = "Media";
        href = "https://jellyfin.echidna-ghost.ts.net";
        icon = "jellyfin.svg";
      };
    };
  };
}
