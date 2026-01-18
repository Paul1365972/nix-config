{ den, ... }:
{
  # Tailscale with Taildrive and Taildrop
  den.aspects.media-server._.tailscale = {
    nixos =
      { pkgs, ... }:
      {
        # Tailscale daemon
        services.tailscale.enable = true;

        # FUSE for rclone mounts
        programs.fuse.userAllowOther = true;

        # Taildrive mount (system service)
        systemd.services.taildrive = {
          description = "Taildrive WebDAV Mount (rclone)";
          requires = [ "tailscaled.service" ];
          after = [
            "tailscaled.service"
            "network-online.target"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "notify";
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /mnt/taildrive";
            ExecStart = ''
              ${pkgs.rclone}/bin/rclone mount :webdav: /mnt/taildrive \
                --webdav-url http://100.100.100.100:8080/ \
                --vfs-cache-mode writes \
                --vfs-cache-max-age 24h \
                --vfs-read-chunk-size 128M \
                --vfs-read-chunk-size-limit off \
                --buffer-size 256M \
                --dir-cache-time 5m \
                --poll-interval 15s \
                --uid 1000 \
                --gid 1000 \
                --allow-other \
                --allow-non-empty \
                --no-checksum
            '';
            ExecStop = "${pkgs.fuse}/bin/fusermount -uz /mnt/taildrive";
            Restart = "on-failure";
            RestartSec = 10;
          };
        };

        environment.systemPackages = with pkgs; [
          rclone
          fuse
        ];
      };

    homeManager =
      { pkgs, config, ... }:
      {
        # Taildrop receiver service
        systemd.user.services.tailreceive = {
          Unit.Description = "File Receiver Service for Taildrop";
          Service = {
            UMask = "0077";
            ExecStart = "${pkgs.tailscale}/bin/tailscale file get --verbose --loop --conflict=rename ${config.home.homeDirectory}/Downloads/";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
  };
}
