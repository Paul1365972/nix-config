{ den, ... }:
{
  # Media server desktop environment
  den.aspects.media-server._.desktop = den.lib.parametric {
    includes = [
      den.aspects.media-server._.labwc
      den.aspects.media-server._.waybar
    ];

    nixos =
      { pkgs, ... }:
      {
        # Enable Wayland
        hardware.graphics.enable = true;

        # Desktop packages
        environment.systemPackages = with pkgs; [
          chromium
          thunar
          mpv
          papirus-icon-theme
        ];

        # Fonts
        fonts.packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          font-awesome
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        # Dark theme
        gtk = {
          enable = true;
          theme.name = "Adwaita-dark";
        };

        # QT theming
        qt = {
          enable = true;
          platformTheme.name = "qtct";
        };

        # Wallpaper
        home.file."Pictures/megumin_wallpaper.png".source = ./assets/megumin_wallpaper.png;

        # Desktop entries
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

        # MPV (wlshm to avoid fd leaks)
        programs.mpv = {
          enable = true;
          config.vo = "wlshm";
        };
      };
  };
}
