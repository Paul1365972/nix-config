_: {
  den.aspects.hyprland-desktop.homeManager =
    { config, ... }:
    let
      c = config.theme.colors;
    in
    {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        settings.main = {
          layer = "top";
          position = "top";
          height = 28;
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [
            "tray"
            "pulseaudio"
            "network"
            "battery"
          ];
          clock.format = "{:%a %d %b  %H:%M}";
          battery = {
            format = "{capacity}% {icon}";
            format-icons = [
              "󰁺"
              "󰁽"
              "󰁿"
              "󰂁"
              "󰁹"
            ];
            states.critical = 15;
          };
          network = {
            format-wifi = "{essid} 󰖩";
            format-ethernet = "󰈀";
            format-disconnected = "󰖪";
          };
          pulseaudio = {
            format = "{volume}% 󰕾";
            format-muted = "󰝟";
          };
        };
        style = ''
          * {
            font-family: "${config.theme.font}";
            font-size: 12px;
            min-height: 0;
          }
          window#waybar {
            background: #${c.bg};
            color: #${c.fg};
          }
          #workspaces button {
            color: #${c.fg};
            padding: 0 6px;
          }
          #workspaces button.active {
            color: #${c.accent};
          }
          #clock, #tray, #pulseaudio, #network, #battery {
            padding: 0 10px;
          }
          #battery.critical {
            color: #${c.alt};
          }
        '';
      };
    };
}
