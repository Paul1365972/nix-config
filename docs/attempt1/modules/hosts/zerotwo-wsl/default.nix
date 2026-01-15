{ inputs, lib, ... }:
{
  flake.hosts.zerotwo-wsl = {
    system = "x86_64-linux";
    user = "paul";

    aspects = [
      "nix"
      "git"
      "shell"
      "localization"
      "networking"
      "paul"
      "terminal"
      "dev-tools"
      "zerotwo-wsl"
    ];

    extraModules = [
      inputs.nixos-wsl.nixosModules.default
    ];
  };

  flake.modules.nixos.zerotwo-wsl = {
    networking.hostName = "zerotwo-wsl";

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    systemd.services.systemd-resolved.enable = lib.mkForce false;  # WSL handles DNS

    boot.kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;  # Increased for VSCode
      "fs.inotify.max_user_instances" = 512;
    };

    system.stateVersion = "25.05";
  };

  flake.modules.homeManager.zerotwo-wsl = {
    home.sessionVariables = {
      DEVELOPMENT_HOST = "true";
      WSL_DISTRO_NAME = "zerotwo-wsl";
    };
  };
}
