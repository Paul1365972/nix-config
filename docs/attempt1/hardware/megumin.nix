# Hardware configuration for megumin (Raspberry Pi 4)
# =====================================================
# This file contains ONLY hardware detection settings.
# Policy decisions belong in modules/hosts/megumin.nix
#
# NOTE: This is a placeholder. Run nixos-generate-config on actual hardware
# and update this file with the generated configuration.

{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Raspberry Pi 4 boot configuration
  boot = {
    # Use extlinux boot loader (required for RPi)
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    # Raspberry Pi 4 kernel
    kernelPackages = pkgs.linuxPackages_rpi4;

    # Kernel parameters
    kernelParams = [
      "console=ttyS0,115200"
      "console=tty1"
      "cma=256M"  # GPU memory allocation
    ];

    # Kernel modules for hardware support
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];
  };

  # Raspberry Pi 4 hardware support
  hardware = {
    # Raspberry Pi firmware
    enableRedistributableFirmware = true;

    # GPU support (enabled via nixos-hardware module)
    raspberry-pi."4" = {
      fkms-3d.enable = true;  # Fake KMS for GPU acceleration
      audio.enable = true;
    };

    # OpenGL for video acceleration
    graphics = {
      enable = true;
    };

    # Bluetooth support
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # File systems - PLACEHOLDER, update with actual UUIDs
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
