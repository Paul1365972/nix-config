{ inputs, lib, ... }:
{
  flake.hosts.megumin = {
    system = "aarch64-linux";
    user = "paul";

    aspects = [
      "nix"
      "git"
      "shell"
      "localization"
      "networking"
      "paul"
      "megumin"
    ];

    extraModules = [
      inputs.hardware.nixosModules.raspberry-pi-4
    ];
  };

  flake.modules.nixos.megumin = {
    networking.hostName = "megumin";

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    boot.kernel.sysctl = {
      "vm.swappiness" = 10; # SD card optimization
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_ratio" = 10;
    };

    services.journald.extraConfig = ''
      Storage=volatile
      RuntimeMaxUse=30M
    '';

    swapDevices = [{
      device = "/swapfile";
      size = 2048;
    }];

    powerManagement = {
      enable = true;
      cpuFreqGovernor = lib.mkDefault "ondemand";
    };

    system.stateVersion = "25.05";
  };

  flake.modules.homeManager.megumin = {
    home.sessionVariables = {
      MEDIA_CENTER = "true";
    };
  };
}
