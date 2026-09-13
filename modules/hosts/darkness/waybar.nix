_: {
  den.aspects.darkness.provides.waybar.homeManager =
    { pkgs, ... }:
    let
      icons = "${pkgs.papirus-icon-theme}/share/icons/Papirus/24x24";
      button = tooltip: on-click: {
        format = " ";
        tooltip = true;
        tooltip-format = tooltip;
        inherit on-click;
      };
    in
    {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        settings.main = {
          position = "bottom";
          layer = "top";
          height = 28;
          spacing = 0;

          modules-left = [
            "custom/shutdown"
            "custom/thunar"
            "custom/chromium"
            "custom/mpv"
            "custom/bluetooth"
          ];
          modules-center = [ "wlr/taskbar" ];
          modules-right = [ "clock" ];

          "custom/shutdown" = button "Shutdown" "systemctl poweroff";
          "custom/thunar" = button "File Manager" "thunar";
          "custom/chromium" = button "Chromium Browser" "systemctl --user start chromium.service";
          "custom/mpv" = button "MPV Player" "mpv --player-operation-mode=pseudo-gui";
          "custom/bluetooth" = button "Bluetooth" "blueman-manager";

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
        };

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
          #custom-bluetooth,
          #taskbar button {
            padding: 2px 6px;
            margin: 2px 3px;
            min-width: 24px;
            min-height: 24px;
            background-color: transparent;
            background-repeat: no-repeat;
            background-size: 20px 20px;
            background-position: center;
            transition: background-color 0.15s ease-in-out;
          }

          #custom-shutdown:hover,
          #custom-thunar:hover,
          #custom-chromium:hover,
          #custom-mpv:hover,
          #custom-bluetooth:hover,
          #taskbar button:hover {
            background-color: #3d3d3d;
          }

          #custom-shutdown:active,
          #custom-thunar:active,
          #custom-chromium:active,
          #custom-mpv:active,
          #custom-bluetooth:active {
            background-color: #1d1d1d;
          }

          #custom-shutdown { background-image: url("${icons}/actions/system-shutdown.svg"); }
          #custom-thunar { background-image: url("${icons}/apps/Thunar.svg"); }
          #custom-chromium { background-image: url("${icons}/apps/chromium-browser.svg"); }
          #custom-mpv { background-image: url("${icons}/apps/mpv.svg"); }
          #custom-bluetooth { background-image: url("${icons}/devices/bluetooth.svg"); }

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
    };
}
