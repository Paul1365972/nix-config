# Raspberry Pi media server aspect
# Configuration for aarch64 RPI running as a media server
{ den, ... }:
{
  den.aspects.rpi = {
    includes = [
      # Add media-server aspects here
      # den.aspects.jellyfin
      # den.aspects.samba
    ];

    nixos = { pkgs, lib, modulesPath, ... }: {
      # RPI-specific boot
      imports = [
        "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
      ];

      # Nix settings
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [ "root" "paul" ];
      };

      # Networking
      networking.networkmanager.enable = true;

      # Enable SSH for remote access
      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
        settings.PermitRootLogin = "no";
      };

      # Timezone
      time.timeZone = "Europe/London"; # Adjust to your timezone

      # Basic packages
      environment.systemPackages = with pkgs; [
        wget
        curl
        git
        vim
        htop
      ];

      # Hardware-specific settings for RPI
      hardware.enableRedistributableFirmware = true;
    };

    homeManager = { pkgs, ... }: {
      # RPI-specific home config (minimal for server)
    };
  };
}
