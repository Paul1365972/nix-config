{ den, ... }:
{
  den.hosts.x86_64-linux.phos.users.paul = { };

  den.aspects.phos = {
    includes = with den.aspects; [
      common
      comin
      ssh-identities
      agents
      binfmt
      audio
      bluetooth
      hardening
      zswap
      power
      hyprland
      autologin
      theme
      kitty
      lock
      notifications
      clipboard
      screenshot
      waybar
    ];

    nixos = {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.initrd.systemd.enable = true;

      networking.networkmanager.enable = true;
    };
  };
}
