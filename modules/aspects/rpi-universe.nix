# RPi Universe - All version-specific settings for nixos-raspberrypi
#
# This file consolidates all RPi version-specific configuration into a single place.
# To update the RPi universe, only change the version here.
{ inputs, den, ... }:
let
  # Single source of truth for RPi stateVersion
  rpiStateVersion = "25.11";
in
{
  # RPi-specific inputs (kept close to usage per den best practice)
  flake-file.inputs = {
    home-manager-rpi = {
      url = "github:nix-community/home-manager/release-${rpiStateVersion}";
      inputs.nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
    };
    # Pin to main branch as recommended by nixos-raspberrypi docs
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
  };

  # Aspect providing RPi-specific stateVersion
  den.aspects.rpi-universe = {
    nixos.system.stateVersion = rpiStateVersion;
    homeManager.home.stateVersion = rpiStateVersion;
  };
}
