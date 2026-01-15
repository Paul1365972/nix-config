# Hardware configuration for sylphy (Framework 16 2nd gen)
# ============================================================
# This file should ONLY contain hardware detection settings.
# Policy decisions (like boot loader choice) belong in the host module.
#
# NOTE: This is a placeholder - run nixos-generate-config on the actual
# hardware and replace this file with the generated hardware-configuration.nix
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules (hardware detection)
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];  # Framework 16 2nd gen uses AMD
  boot.extraModulePackages = [ ];

  # Filesystems - placeholder, update with actual partitions
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER-UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER-UUID";
    fsType = "vfat";
  };

  # Swap configuration
  swapDevices = [ ];

  # Hardware settings
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Framework-specific optimizations
  # Uncomment and adjust these based on actual hardware
  # hardware.framework.enableKmod = true;
  # services.fprintd.enable = true;  # Fingerprint reader

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
