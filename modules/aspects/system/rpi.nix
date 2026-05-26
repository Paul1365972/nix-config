{ ... }:
{
  flake-file.inputs.nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

  den.aspects.rpi = {
    nixos =
      {
        lib,
        nixos-raspberrypi,
        ...
      }:
      {
        imports = [ nixos-raspberrypi.nixosModules.sd-image ];

        boot.loader.raspberry-pi.bootloader = "kernel";

        # profiles/base.nix pulls ZFS in but its kernel module doesn't match the
        # cached-nixpkgs userspace tooling on the RPi kernel.
        boot.supportedFilesystems.zfs = lib.mkForce false;
      };
  };
}
