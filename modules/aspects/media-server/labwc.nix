{ den, ... }:
{
  # Labwc Wayland compositor
  den.aspects.media-server._.labwc =
    { user, ... }:
    {
      nixos =
        { pkgs, ... }:
        {
          # Labwc compositor with greetd auto-login
          services.greetd = {
            enable = true;
            settings.default_session = {
              command = "${pkgs.labwc}/bin/labwc";
              user = user.userName;
            };
          };

          environment.systemPackages = with pkgs; [
            labwc
            swaybg
            wl-clipboard
          ];
        };

      homeManager = {
        xdg.configFile = {
          "labwc/rc.xml".source = ./config/labwc/rc.xml;
          "labwc/environment".source = ./config/labwc/environment;
          "labwc/autostart" = {
            source = ./config/labwc/autostart;
            executable = true;
          };
        };
      };
    };
}
