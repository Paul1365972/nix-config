{ den, ... }:
{
  den.aspects.phos = {
    includes = [
      den.aspects.common
      den.aspects.hyprland
      den.aspects.autologin
      den.aspects.binfmt
    ];

    nixos =
      { pkgs, ... }:
      {
        # Bootloader for dual-boot
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        # Networking
        networking.networkmanager.enable = true;

        # Bluetooth
        hardware.bluetooth.enable = true;
        services.blueman.enable = true;

        # Sound
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
        };
      };
  };
}
