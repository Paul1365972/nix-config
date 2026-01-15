# Laptop host aspect
# Configuration for a NixOS laptop
{ den, ... }:
{
  den.aspects.laptop = {
    includes = [
      den.aspects.audio
      # Add more laptop-specific aspects here
      # den.aspects.bluetooth
      # den.aspects.desktop
    ];

    nixos = { pkgs, lib, ... }: {
      # Boot configuration
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Networking
      networking.networkmanager.enable = true;

      # Power management
      services.tlp.enable = true;
      services.thermald.enable = true;

      # Nix settings
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [ "root" "paul" ];
      };

      # Timezone and locale
      time.timeZone = "Europe/London"; # Adjust to your timezone
      i18n.defaultLocale = "en_GB.UTF-8";

      # Basic system packages
      environment.systemPackages = with pkgs; [
        wget
        curl
        git
        vim
      ];
    };

    homeManager = { pkgs, ... }: {
      # Laptop-specific home config
    };
  };
}
