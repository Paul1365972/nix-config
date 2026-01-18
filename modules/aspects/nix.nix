{ ... }:
{
  den.aspects.nix = {
    nixos = {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;

        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://hyprland.cachix.org"
          "https://nixos-raspberrypi.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];

        allowed-users = [ "@wheel" ];
        trusted-users = [
          "root"
          "@wheel"
        ];

        max-jobs = "auto";
      };

      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };

      nix.optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };

      nix.channel.enable = false;
    };
  };
}
