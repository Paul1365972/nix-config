_: {
  den.aspects.darkness.provides.desktop = {
    nixos =
      { pkgs, ... }:
      {
        hardware.graphics.enable = true;
        programs.dconf.enable = true;

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
          papirus-icon-theme
        ];

        fonts.packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          font-awesome
        ];
      };

    homeManager =
      { pkgs, lib, ... }:
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

        systemd.user.services.chromium = {
          Unit = {
            Description = "Kiosk browser";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${lib.getExe pkgs.chromium} --restore-last-session --disable-session-crashed-bubble --password-store=basic";
            Restart = "on-failure";
            RestartSec = 2;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        # wlshm avoids the GBM fd-leak on Pi-class GPUs.
        programs.mpv = {
          enable = true;
          config.vo = "wlshm";
        };
      };
  };
}
