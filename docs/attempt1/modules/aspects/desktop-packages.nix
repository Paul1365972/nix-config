{ ... }:
{
  flake.modules.homeManager.desktop-packages = { pkgs, ... }: {
    home.packages = with pkgs; [
      wl-clipboard
      wlr-randr
      swww

      grim
      slurp

      pavucontrol
      brightnessctl
      playerctl

      htop
      btop

      networkmanagerapplet

      rofi
    ];
  };
}
