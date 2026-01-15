{ inputs, ... }:
let
  gapsInner = 4;
  gapsOuter = 8;
  borderSize = 2;
  layoutType = "dwindle";

  modKey = "SUPER";

  terminalApp = "wezterm";
  browserApp = "firefox";
  launcherApp = "rofi -show drun";
in
{
  flake.modules.nixos.hyprland = { pkgs, ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    security.polkit.enable = true;
  };

  flake.modules.homeManager.hyprland = {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;  # Use system package
      portalPackage = null;
      xwayland.enable = true;

      settings = {
        general = {
          gaps_in = gapsInner;
          gaps_out = gapsOuter;
          border_size = borderSize;
          layout = layoutType;
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        monitor = [
          ",preferred,auto,1"
        ];

        "$mod" = modKey;
        bind = [
          "$mod, F, exec, ${browserApp}"
          "$mod, W, exec, ${terminalApp}"
          "$mod, T, exec, xterm"
          "$mod, Space, exec, ${launcherApp}"
          ", Escape, exec, hyprctl dispatch exit"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
      };
    };
  };
}
