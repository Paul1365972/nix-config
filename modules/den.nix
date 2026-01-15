{ inputs, ... }:
{
  # Raspberry Pi home cinema
  den.hosts.aarch64-linux.darkness = {
    users.paul = { };
    hm-module = inputs.home-manager-rpi.nixosModules.home-manager;
    instantiate = args: inputs.nixos-raspberrypi.lib.nixosInstaller (args // {
      specialArgs.nixos-raspberrypi = inputs.nixos-raspberrypi;
    });
  };

  # WSL instance
  den.hosts.x86_64-linux.phos-wsl.users.paul = { };

  # Laptop
  den.hosts.x86_64-linux.phos.users.paul = { };
}
