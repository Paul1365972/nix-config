{ ... }:
{
  den.aspects.darkness.provides.labwc =
    { host, ... }:
    {
      nixos =
        { pkgs, ... }:
        {
          services.greetd = {
            enable = true;
            settings.default_session = {
              command = "${pkgs.labwc}/bin/labwc";
              user = host.users.${builtins.head (builtins.attrNames host.users)}.userName;
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
