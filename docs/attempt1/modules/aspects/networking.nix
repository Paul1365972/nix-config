{ ... }:
{
  flake.modules.nixos.networking = {
    networking.networkmanager.enable = true;

    services.dbus.enable = true;
  };
}
