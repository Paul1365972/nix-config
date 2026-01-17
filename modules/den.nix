{ inputs, ... }:
{
  # Raspberry Pi home cinema
  # Use nixosSystem (not nixosInstaller/nixosSystemFull) to avoid uncached
  # package overlays (ffmpeg-rpi, vlc-rpi, etc.) that cause hours of builds.
  # We still get kernel, firmware, and bootloader support.
  den.hosts.aarch64-linux.darkness = {
    users.paul = { };
    # Custom instantiate needed because nixos-raspberrypi.lib.nixosSystem:
    # - Injects RPi kernel/firmware/bootloader overlays
    # - Requires specialArgs.nixos-raspberrypi for hardware modules
    # - We override nixpkgs to use standard (cached) instead of their fork
    instantiate = args: inputs.nixos-raspberrypi.lib.nixosSystem (args // {
      nixpkgs = inputs.nixpkgs;
      specialArgs.nixos-raspberrypi = inputs.nixos-raspberrypi;
    });
  };

  # WSL instance
  den.hosts.x86_64-linux.phos-wsl.users.paul = { };

  # Laptop
  den.hosts.x86_64-linux.phos.users.paul = { };
}
