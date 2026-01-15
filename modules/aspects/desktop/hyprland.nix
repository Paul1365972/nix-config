{ den, ... }:
{
  den.aspects.hyprland = {
    nixos =
      { pkgs, ... }:
      {
        programs.hyprland.enable = true;

        # Display manager with tuigreet
        services.greetd = {
          enable = true;
          settings.default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
            user = "greeter";
          };
        };

        # Minimal Wayland essentials
        environment.systemPackages = with pkgs; [
          kitty
          wofi
        ];
      };
  };
}
