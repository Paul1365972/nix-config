{ ... }:
{
  den.aspects.hyprland = {
    nixos =
      { pkgs, ... }:
      {
        programs.hyprland.enable = true;

        services.greetd = {
          enable = true;
          settings.default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
            user = "greeter";
          };
        };

        environment.systemPackages = with pkgs; [
          wofi
        ];
      };
  };
}
