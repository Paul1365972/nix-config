{
  __findFile,
  den,
  lib,
  ...
}:
{
  # Global static settings
  den.default = {
    nixos.system.stateVersion = lib.mkDefault "26.05";
    homeManager.home.stateVersion = lib.mkDefault "26.05";
  };

  # Default includes for all hosts/users
  den.default.includes = [
    # Enable home-manager on all hosts
    <den/home-manager>

    # Automatically create the user on host
    <den/define-user>

    # Set hostname from host data
    (den.lib.take.exactly (
      { OS, host }:
      den.lib.take.unused OS {
        nixos.networking.hostName = host.hostName;
      }
    ))
  ];
}
