{ den, ... }:
{
  den.hosts.x86_64-linux.phos.users.paul = { };

  den.aspects.phos = {
    includes = with den.aspects; [
      common
      comin
      binfmt
      hardening
      network-performance
      zswap
      power
      hyprland-desktop
    ];

    nixos = {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.initrd.systemd.enable = true;

      networking.networkmanager.enable = true;
    };
  };
}
