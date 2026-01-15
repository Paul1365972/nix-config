# Hardware configuration for zerotwo-wsl (WSL2 environment)
# ===========================================================
# This file contains ONLY WSL-specific integration settings.
# The NixOS-WSL module handles most configuration automatically (But we forgot to include it?!!).
# Policy decisions (hostname, services, etc.) belong in modules/hosts/zerotwo-wsl/

{ lib, ... }:
{
  # Enable WSL integration
  wsl = {
    enable = true;
    defaultUser = "paul";

    startMenuLaunchers = true;

    # Windows integration settings
    wslConf = {
      automount.root = "/mnt";
      interop.enabled = true;
      network.generateHosts = true;
      network.generateResolvConf = true;
    };
  };

  # WSL runs in a container
  boot.isContainer = true;

  # Disable boot loader (WSL doesn't need it)
  boot.loader.grub.enable = false;

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
