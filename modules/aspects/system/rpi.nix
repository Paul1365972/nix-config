{ inputs, ... }:
{
  flake-file.inputs.nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

  den.aspects.rpi.nixos =
    { lib, pkgs, ... }:
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

      # nixpkgs 26.11 reads kernel.buildDTBs and kernel.target, which the vendored RPi kernel
      # doesn't define yet; graft them on (no rebuild). The option's `apply` re-invokes
      # kernel.override, so the graft must wrap override to survive it.
      boot.kernelPackages =
        let
          base = inputs.nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_rpi5;
          graft =
            kernel:
            kernel
            // {
              target = "Image";
              buildDTBs = true;
              override = args: graft (kernel.override args);
            };
        in
        base.extend (_: prev: { kernel = graft prev.kernel; });

      # base profile enables ZFS, but the RPi kernel and nixpkgs userspace zfs don't match.
      boot.supportedFilesystems.zfs = lib.mkForce false;
    };
}
