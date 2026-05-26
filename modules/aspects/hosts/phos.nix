{ den, ... }:
{
  den.aspects.phos = {
    includes = [
      den.aspects.common
      den.aspects.hyprland
      den.aspects.autologin
      den.aspects.binfmt
      den.aspects.audio
      den.aspects.bluetooth
      den.aspects.auto-upgrade
      den.aspects.ssh
      den.aspects.kitty
      den.aspects.hardening
      den.aspects.zswap
      den.aspects.rice
    ];

    nixos = {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.networkmanager.enable = true;
    };
  };
}
