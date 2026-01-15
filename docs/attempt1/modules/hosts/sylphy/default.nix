{ ... }:
{
  flake.hosts.sylphy = {
    system = "x86_64-linux";
    user = "paul";

    aspects = [
      "nix"
      "git"
      "shell"
      "localization"
      "networking"
      "fonts"
      "hyprland"
      "audio"
      "paul"
      "firefox"
      "terminal"
      "dev-tools"
      "desktop-packages"
      "sylphy"
    ];
  };

  flake.modules.nixos.sylphy = {
    networking.hostName = "sylphy";

    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 5;
    };

    services.libinput.enable = true;

    services.fstrim.enable = true;

    powerManagement = {
      enable = true;
      powertop.enable = true;
    };

    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      };
    };

    system.stateVersion = "25.05";
  };

  flake.modules.homeManager.sylphy = {
    home.sessionVariables = {
      LAPTOP = "true";
    };
  };
}
