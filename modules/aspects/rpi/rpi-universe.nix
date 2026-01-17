# RPi Universe - Raspberry Pi hardware support using nixos-raspberrypi
#
# This aspect includes the rpi-fix workaround that allows using standard cached
# nixpkgs with nixos-raspberrypi modules.
{ den, ... }:
{
  flake-file.inputs = {
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
  };

  # Aspect for RPi hosts
  den.aspects.rpi-universe = {
    includes = [ den.aspects.rpi-fix ];
  };
}
