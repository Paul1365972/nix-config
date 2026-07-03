{ den, ... }:
{
  den.aspects.saber = {
    includes = with den.aspects.saber.provides; [
      den.aspects.common
      den.aspects.comin
      den.aspects.auto-reboot
      den.aspects.hardening
      den.aspects.tailscale
      hardware
      disko
      filesystems
      networking
      postgres
      redis
      caddy
      authentik
      matrix
      element
      # matrix-bridges
      maubot
      nextcloud
      jellyfin
      traccar
      mosquitto
      zigbee2mqtt
      home-assistant
      homepage
      cloudflare-ddns
    ];

    nixos = {
      services.tailscale.extraUpFlags = [ "--advertise-exit-node" ];
      # --advertise-exit-node only works if the kernel forwards packets; useRoutingFeatures = "server" sets the v4/v6 forward sysctls.
      services.tailscale.useRoutingFeatures = "server";
    };
  };
}
