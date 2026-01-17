{ den, ... }:
let
  wallpaper = ./assets/megumin_wallpaper.png;
in
{
  # Media server desktop environment (labwc + waybar + chromium)
  den.aspects.media-server._.desktop = {
    nixos =
      { pkgs, ... }:
      {
        # Enable Wayland
        hardware.graphics.enable = true;

        # Labwc compositor with auto-login
        services.greetd = {
          enable = true;
          settings.default_session = {
            command = "${pkgs.labwc}/bin/labwc";
            user = "paul";
          };
        };

        # Passwordless shutdown
        security.sudo.extraRules = [{
          users = [ "paul" ];
          commands = [{
            command = "/run/current-system/sw/bin/shutdown";
            options = [ "NOPASSWD" ];
          }];
        }];

        # Desktop packages
        environment.systemPackages = with pkgs; [
          # Compositor and panel
          labwc
          waybar
          swaybg
          wl-clipboard

          # Browser
          chromium

          # File manager and media
          thunar
          mpv

          # Theming
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
        home.file."Pictures/megumin_wallpaper.png".source = wallpaper;

        # Desktop entries
        xdg.desktopEntries = {
          chromium-custom = {
            name = "Chromium";
            comment = "Web Browser";
            exec = "chromium --restore-last-session --disable-session-crashed-bubble --password-store=basic";
            icon = "chromium";
            type = "Application";
            categories = [ "Network" "WebBrowser" ];
          };
          shutdown = {
            name = "Shutdown";
            icon = "system-shutdown";
            exec = "sudo shutdown -h now";
            type = "Application";
            terminal = false;
          };
        };

        # Labwc autostart
        xdg.configFile."labwc/autostart" = {
          executable = true;
          text = ''
            #!/bin/bash

            # Set themes
            export GTK_THEME=Adwaita:dark
            export QT_QPA_PLATFORMTHEME=qt5ct

            # Start Waybar panel
            waybar &

            # Set wallpaper
            swaybg -i ~/Pictures/megumin_wallpaper.png -m fill &

            # Start Chromium
            gtk-launch chromium-custom &
          '';
        };

        # Labwc environment
        xdg.configFile."labwc/environment".text = ''
          XDG_SESSION_TYPE=wayland
          XDG_CURRENT_DESKTOP=labwc
          QT_QPA_PLATFORM=wayland
          QT_QPA_PLATFORMTHEME=qt5ct
          QT_WAYLAND_DISABLE_WINDOWDECORATION=1
          QT_AUTO_SCREEN_SCALE_FACTOR=1
          MOZ_ENABLE_WAYLAND=1
          GDK_BACKEND=wayland
          XCURSOR_SIZE=24
          XCURSOR_THEME=default
        '';

        # Labwc rc.xml
        xdg.configFile."labwc/rc.xml".text = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <labwc_config>
            <focus>
              <followMouse>no</followMouse>
              <raiseOnFocus>yes</raiseOnFocus>
            </focus>

            <theme>
              <name>Clearlooks</name>
              <cornerRadius>0</cornerRadius>
            </theme>

            <cursor>
              <theme>default</theme>
            </cursor>

            <keyboard>
              <repeatRate>25</repeatRate>
              <repeatDelay>300</repeatDelay>
              <keybind key="A-Tab"><action name="NextWindow"/></keybind>
              <keybind key="A-S-Tab"><action name="PreviousWindow"/></keybind>
              <keybind key="A-F4"><action name="Close"/></keybind>
            </keyboard>

            <resistance>
              <screenEdgeStrength>20</screenEdgeStrength>
            </resistance>

            <placement>
              <policy>center</policy>
            </placement>

            <desktops>
              <number>1</number>
              <popupTime>0</popupTime>
            </desktops>

            <libinput>
              <device category="default">
                <naturalScroll>no</naturalScroll>
              </device>
            </libinput>

            <core>
              <gap>0</gap>
            </core>
          </labwc_config>
        '';

        # Waybar
        programs.waybar = {
          enable = true;
          settings = [{
            position = "bottom";
            layer = "top";
            height = 28;
            spacing = 0;
            autohide = true;
            autohide-delay = 1;

            modules-left = [ "custom/shutdown" "custom/thunar" "custom/chromium" "custom/mpv" ];
            modules-center = [ "wlr/taskbar" ];
            modules-right = [ "clock" ];

            "custom/shutdown" = {
              format = " ";
              on-click = "gtk-launch shutdown";
              tooltip = true;
              tooltip-format = "Shutdown";
            };
            "custom/thunar" = {
              format = " ";
              on-click = "thunar";
              tooltip = true;
              tooltip-format = "File Manager";
            };
            "custom/chromium" = {
              format = " ";
              on-click = "gtk-launch chromium-custom";
              tooltip = true;
              tooltip-format = "Chromium Browser";
            };
            "custom/mpv" = {
              format = " ";
              on-click = "mpv";
              tooltip = true;
              tooltip-format = "MPV Player";
            };
            "wlr/taskbar" = {
              format = "{icon} {title}";
              icon-size = 16;
              icon-theme = "hicolor";
              active-first = true;
              tooltip-format = "{title}";
              on-click = "activate";
              on-click-middle = "close";
              on-click-right = "minimize";
              max-length = 30;
            };
            clock = {
              interval = 60;
              format = "{:%H:%M}";
              format-alt = "{:%a %d %b}";
              tooltip-format = "{:%A, %B %d, %Y}";
            };
          }];

          style = ''
            * {
              border: none;
              border-radius: 0;
              font-family: sans;
              font-size: 10px;
              min-height: 0;
            }

            window#waybar {
              background-color: #2d2d2d;
              color: #e3e3e3;
            }

            #custom-shutdown,
            #custom-thunar,
            #custom-chromium,
            #custom-mpv,
            #taskbar button {
              padding: 2px 6px;
              margin: 2px;
              background-color: transparent;
              transition: background-color 0.15s ease-in-out;
            }

            #custom-shutdown,
            #custom-thunar,
            #custom-chromium,
            #custom-mpv {
              margin: 2px 3px;
              min-width: 24px;
              min-height: 24px;
              background-repeat: no-repeat;
              background-size: 20px 20px;
              background-position: center;
            }

            #custom-shutdown { background-image: url("${pkgs.papirus-icon-theme}/share/icons/Papirus/24x24/actions/system-shutdown.svg"); }
            #custom-thunar { background-image: url("${pkgs.papirus-icon-theme}/share/icons/Papirus/24x24/apps/Thunar.svg"); }
            #custom-chromium { background-image: url("${pkgs.papirus-icon-theme}/share/icons/Papirus/24x24/apps/chromium-browser.svg"); }
            #custom-mpv { background-image: url("${pkgs.papirus-icon-theme}/share/icons/Papirus/24x24/apps/mpv.svg"); }

            #custom-shutdown:hover,
            #custom-thunar:hover,
            #custom-chromium:hover,
            #custom-mpv:hover,
            #taskbar button:hover {
              background-color: #3d3d3d;
            }

            #custom-shutdown:active,
            #custom-thunar:active,
            #custom-chromium:active,
            #custom-mpv:active {
              background-color: #1d1d1d;
            }

            #taskbar button.active {
              color: #ffffff;
            }

            tooltip {
              background-color: #2d2d2d;
              color: #dddddd;
              border: 1px solid #2d2d2d;
              padding: 8px 4px;
            }

            #clock {
              padding: 2px 8px;
              margin: 2px;
              font-weight: bold;
            }
          '';
        };

        # MPV (wlshm to avoid fd leaks)
        programs.mpv = {
          enable = true;
          config.vo = "wlshm";
        };
      };
  };
}
