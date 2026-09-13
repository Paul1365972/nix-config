{ inputs, lib, ... }:
{
  den.aspects.nix.nixos =
    { pkgs, ... }:
    {
      nix.package = pkgs.nixVersions.latest;
      nix.channel.enable = false;

      # Pin <nixpkgs> et al. and the registry to flake inputs so imperative
      # `nix shell` / `nix-shell` resolves to the same locked versions.
      nix.nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") inputs;
      nix.registry = lib.mapAttrs (_: v: { flake = v; }) inputs;
      nix.settings.flake-registry = "";

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;

        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
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

      nix.optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };
    };
}
