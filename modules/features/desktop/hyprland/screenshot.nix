_: {
  den.aspects.hyprland-desktop.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        grim
        slurp
        hyprshot
      ];
    };
}
