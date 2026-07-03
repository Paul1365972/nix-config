{ ... }:
{
  den.aspects.lock = {
    nixos.security.pam.services.hyprlock = { };

    provides.to-users.homeManager =
      { osConfig, ... }:
      let
        c = osConfig.rice.current.colors;
      in
      {
        programs.hyprlock = {
          enable = true;
          settings = {
            general.hide_cursor = true;
            background = [
              {
                monitor = "";
                color = "rgb(${c.bg})";
              }
            ];
            input-field = [
              {
                monitor = "";
                size = "300, 50";
                outline_thickness = 2;
                outer_color = "rgb(${c.accent})";
                inner_color = "rgb(${c.bg})";
                font_color = "rgb(${c.fg})";
                check_color = "rgb(${c.alt})";
                placeholder_text = "";
              }
            ];
          };
        };

        services.hypridle = {
          enable = true;
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || hyprlock";
              before_sleep_cmd = "loginctl lock-session";
              after_sleep_cmd = "hyprctl dispatch dpms on";
            };
            listener = [
              {
                timeout = 300;
                on-timeout = "loginctl lock-session";
              }
              {
                timeout = 600;
                on-timeout = "hyprctl dispatch dpms off";
                on-resume = "hyprctl dispatch dpms on";
              }
              {
                timeout = 1800;
                on-timeout = "systemctl suspend";
              }
            ];
          };
        };
      };
  };
}
