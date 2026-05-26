{ den, ... }:
{
  den.aspects.darkness.provides.desktop = {
    includes = with den.aspects.darkness.provides; [
      labwc
      waybar
      den.aspects.autologin
    ];

    nixos =
      { pkgs, ... }:
      {
        hardware.graphics.enable = true;
        programs.dconf.enable = true;

        # Passwordless power management for the kiosk's "users" group.
        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if ((action.id == "org.freedesktop.login1.power-off" ||
                 action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
                 action.id == "org.freedesktop.login1.reboot" ||
                 action.id == "org.freedesktop.login1.reboot-multiple-sessions") &&
                subject.isInGroup("users")) {
              return polkit.Result.YES;
            }
          });
        '';

        environment.systemPackages = with pkgs; [
          chromium
          thunar
          mpv
          papirus-icon-theme
          gtk3 # for gtk-launch
        ];

        fonts.packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          font-awesome
        ];
      };

    homeManager =
      { ... }:
      {
        xdg.enable = true;
        dconf.enable = true;

        gtk = {
          enable = true;
          theme.name = "Adwaita-dark";
        };

        qt = {
          enable = true;
          platformTheme.name = "qtct";
        };

        home.file."Pictures/megumin_wallpaper.png".source = ./assets/megumin_wallpaper.png;

        xdg.desktopEntries = {
          chromium-custom = {
            name = "Chromium";
            comment = "Web Browser";
            exec = "chromium --restore-last-session --disable-session-crashed-bubble --password-store=basic";
            icon = "chromium";
            type = "Application";
            categories = [
              "Network"
              "WebBrowser"
            ];
          };
          shutdown = {
            name = "Shutdown";
            icon = "system-shutdown";
            exec = "systemctl poweroff";
            type = "Application";
            terminal = false;
          };
        };

        # wlshm avoids the GBM fd-leak on Pi-class GPUs.
        programs.mpv = {
          enable = true;
          config.vo = "wlshm";
        };
      };
  };
}
