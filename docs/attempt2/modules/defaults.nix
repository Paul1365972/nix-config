# Global defaults applied to all hosts, users, and homes
{ den, ... }:
{
  # State versions - set these once and don't change
  den.default = {
    nixos.system.stateVersion = "24.11";
    homeManager.home.stateVersion = "24.11";
  };

  # Default includes for all configurations
  den.default.includes = [
    # Enable home-manager integration on all hosts
    den.provides.home-manager

    # Automatically create users on hosts
    den.provides.define-user

    # Set networking.hostName from host definition
    (den.lib.take.exactly (
      { OS, host }:
      den.lib.take.unused OS {
        nixos.networking.hostName = host.hostName;
      }
    ))
  ];
}
