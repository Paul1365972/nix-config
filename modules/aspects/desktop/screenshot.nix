{ ... }:
{
  den.aspects.screenshot.provides.to-users.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        grim
        slurp
        hyprshot
      ];
    };
}
