{
  den.aspects.saber.nixos = {
    networking.useNetworkd = true;
    networking.useDHCP = false;
    systemd.network.networks."10-lan" = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };
    networking.firewall.enable = true;
    services.tailscale.extraSetFlags = [ "--advertise-exit-node" ];
    services.tailscale.useRoutingFeatures = "server";
  };
}
