{ ... }:
{
  den.aspects.darkness.provides.waybar = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.waybar ];
      };

    homeManager =
      { pkgs, ... }:
      {
        xdg.configFile = {
          "waybar/config".source = ./config/waybar/config.json;
          "waybar/style.css".source = pkgs.replaceVars ./config/waybar/style.css {
            icons = "${pkgs.papirus-icon-theme}/share/icons/Papirus";
          };
        };
      };
  };
}
