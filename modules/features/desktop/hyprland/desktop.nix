{ den, ... }:
{
  den.aspects.hyprland-desktop.includes = with den.aspects; [
    audio
    bluetooth
    theme
    kitty
  ];
}
