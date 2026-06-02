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
        # Caddy auto-serves HTTP/3 on UDP/443.
        allowedUDPPorts = [ 443 ];
        # Traccar exposes one port per GPS device protocol family.
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
