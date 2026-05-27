{ inputs, ... }:
{
  # Custom instantiate: nixos-raspberrypi.lib.nixosSystem injects Pi kernel
  # and firmware overlays and expects specialArgs.nixos-raspberrypi.
  # We override nixpkgs back to upstream so cached packages stay usable.
  den.hosts.aarch64-linux.darkness = {
    form = "embedded";
    users.paul = { };
    instantiate =
      args:
      inputs.nixos-raspberrypi.lib.nixosSystem (
        args
        // {
          nixpkgs = inputs.nixpkgs;
          specialArgs.nixos-raspberrypi = inputs.nixos-raspberrypi;
        }
      );
  };

  den.hosts.x86_64-linux.phos-wsl = {
    form = "wsl";
    wsl.enable = true;
    users.paul = { };
  };

  den.hosts.x86_64-linux.phos = {
    form = "laptop";
    users.paul = { };
  };

  den.hosts.x86_64-linux.saber = {
    form = "server";
    users.paul = { };
  };
}
