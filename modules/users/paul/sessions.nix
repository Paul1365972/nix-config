{
  den.aspects.paul.provides = {
    phos =
      { user, ... }:
      {
        nixos =
          { pkgs, ... }:
          {
            services.greetd.settings.initial_session = {
              user = user.userName;
              command = "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
            };
            virtualisation.vmVariant.users.users.${user.userName}.initialPassword = "phos";
          };
      };

    darkness =
      { user, ... }:
      {
        nixos =
          { pkgs, ... }:
          {
            services.greetd.settings.default_session = {
              user = user.userName;
              command = "${pkgs.labwc}/bin/labwc";
            };
          };
      };
  };
}
