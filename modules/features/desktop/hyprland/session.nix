_: {
  den.aspects.hyprland-desktop.nixos =
    { pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland-uwsm.desktop'";
          user = "greeter";
        };
      };

      environment.systemPackages = with pkgs; [
        wofi
      ];
    };
}
