{ inputs, ... }:
{
  flake-file.inputs.nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

  den.aspects.rpi.nixos =
    { lib, ... }:
    {
      imports = [
        inputs.nixos-raspberrypi.nixosModules.sd-image
        # Vendor overlays (raspberrypi-utils, rpi kernel/firmware).
        inputs.nixos-raspberrypi.lib.inject-overlays
        inputs.nixos-raspberrypi.nixosModules.trusted-nix-caches
      ];

      # Board modules read this; nixos-raspberrypi.lib.nixosSystem would set it via specialArgs.
      _module.args.nixos-raspberrypi = inputs.nixos-raspberrypi;

      boot.loader.raspberry-pi.bootloader = "kernel";

      # base profile enables ZFS, but the RPi kernel and nixpkgs userspace zfs don't match.
      boot.supportedFilesystems.zfs = lib.mkForce false;
    };
}
