{
  den.aspects.nix.nixos =
    { pkgs, ... }:
    {
      nix.package = pkgs.nixVersions.latest;
      nix.channel.enable = false;

      nix.settings.flake-registry = "";

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;

        substituters = [
          "https://nix-community.cachix.org"
        ];

        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
    };
}
