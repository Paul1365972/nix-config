_: {
  den.aspects.darkness.provides.labwc =
    { host, ... }:
    {
      nixos =
        { pkgs, ... }:
        {
          programs.labwc.enable = true;

          services.greetd = {
            enable = true;
            settings.default_session = {
              command = "${pkgs.labwc}/bin/labwc";
              user = host.users.${builtins.head (builtins.attrNames host.users)}.userName;
            };
          };
        };

      homeManager =
        { pkgs, ... }:
        {
          wayland.windowManager.labwc = {
            enable = true;
            rc = {
              focus = {
                followMouse = "no";
                raiseOnFocus = "yes";
              };
              theme = {
                name = "Clearlooks";
                cornerRadius = 0;
              };
              cursor.theme = "default";
              keyboard = {
                repeatRate = 25;
                repeatDelay = 300;
                keybind = [
                  {
                    "@key" = "A-Tab";
                    action."@name" = "NextWindow";
                  }
                  {
                    "@key" = "A-S-Tab";
                    action."@name" = "PreviousWindow";
                  }
                  {
                    "@key" = "A-F4";
                    action."@name" = "Close";
                  }
                ];
              };
              resistance.screenEdgeStrength = 20;
              placement.policy = "center";
              desktops = {
                number = 1;
                popupTime = 0;
              };
              libinput.device = {
                "@category" = "default";
                naturalScroll = "no";
              };
              core.gap = 0;
            };
            environment = [
              "XDG_SESSION_TYPE=wayland"
              "XDG_CURRENT_DESKTOP=labwc"
              "NIXOS_OZONE_WL=1"
              "QT_QPA_PLATFORM=wayland"
              "QT_QPA_PLATFORMTHEME=qt5ct"
              "QT_WAYLAND_DISABLE_WINDOWDECORATION=1"
              "QT_AUTO_SCREEN_SCALE_FACTOR=1"
              "MOZ_ENABLE_WAYLAND=1"
              "GDK_BACKEND=wayland"
              "XCURSOR_SIZE=24"
              "XCURSOR_THEME=default"
            ];
          };

          systemd.user.services.swaybg = {
            Unit = {
              Description = "Wallpaper";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${./assets/megumin_wallpaper.png} -m fill";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "graphical-session.target" ];
          };
        };
    };
}
