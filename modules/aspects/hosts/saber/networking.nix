{ ... }:
{
  den.aspects.saber.provides.networking = {
    nixos = {
      networking.useNetworkd = true;
      networking.useDHCP = false;
      systemd.network.networks."10-lan" = {
        matchConfig.Type = "ether";
        networkConfig.DHCP = "yes";
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [
          80
          443
        ];
        # Traccar GPS device protocols (one port per protocol family).
        allowedTCPPortRanges = [
          {
            from = 5000;
            to = 5059;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 5000;
            to = 5059;
          }
        ];
      };
    };
  };
}
