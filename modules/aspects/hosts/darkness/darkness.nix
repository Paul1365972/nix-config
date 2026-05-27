{ den, inputs, ... }:
{
  den.aspects.darkness = {
    includes = with den.aspects.darkness.provides; [
      den.aspects.common
      den.aspects.rpi
      den.aspects.auto-upgrade
      den.aspects.tailscale
      wireless
      taildrive
      audio
      desktop
    ];

    provides.to-users.includes = with den.aspects.darkness.provides; [
      taildrive
      audio
      desktop
    ];

    nixos = {
      imports = with inputs.nixos-raspberrypi.nixosModules; [
        raspberry-pi-5.base
        raspberry-pi-5.display-vc4
        raspberry-pi-5.bluetooth
      ];

      system.autoUpgrade.allowReboot = true;
      system.autoUpgrade.rebootWindow = {
        lower = "04:00";
        upper = "05:00";
      };
    };
  };
}
