{ inputs, __findFile, den, ... }:
{
  den.aspects.darkness = {
    includes = [
      den.aspects.common
      den.aspects.rpi-universe
      <media-server/wireless>
      <media-server/tailscale>
      <media-server/audio>
      <media-server/desktop>
    ];

    nixos = { nixos-raspberrypi, ... }: {
      imports = with nixos-raspberrypi.nixosModules; [
        raspberry-pi-5.base
        raspberry-pi-5.page-size-16k
        raspberry-pi-5.display-vc4
        raspberry-pi-5.bluetooth
      ];

      boot.loader.raspberryPi.bootloader = "kernel";
      networking.hostName = "darkness";
    };
  };
}
