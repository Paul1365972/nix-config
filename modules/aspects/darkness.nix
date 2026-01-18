{
  inputs,
  __findFile,
  den,
  ...
}:
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

    nixos =
      { nixos-raspberrypi, modulesPath, ... }:
      {
        imports = [
          # SD card image support (auto-configures filesystems)
          nixos-raspberrypi.nixosModules.sd-image
        ]
        ++ (with nixos-raspberrypi.nixosModules; [
          raspberry-pi-5.base
          # No application we use depends on jemalloc, it's safe for now
          # Including this would cause a long compilation step
          #raspberry-pi-5.page-size-16k
          raspberry-pi-5.display-vc4
          raspberry-pi-5.bluetooth
        ]);

        boot.loader.raspberryPi.bootloader = "kernel";
      };
  };
}
