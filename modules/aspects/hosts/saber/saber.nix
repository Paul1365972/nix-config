{ den, ... }:
{
  den.aspects.saber = {
    includes = with den.aspects.saber.provides; [
      den.aspects.common
      den.aspects.auto-upgrade
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
      # backups
    ];

    nixos = {
      networking.hostName = "saber";

      services.tailscale.extraUpFlags = [ "--advertise-exit-node" ];
      # --advertise-exit-node only works if the kernel forwards packets; useRoutingFeatures = "server" sets the v4/v6 forward sysctls.
      services.tailscale.useRoutingFeatures = "server";

      # Synapse pulls in libolm 3.x for E2EE; flagged insecure upstream but no drop-in replacement yet.
      nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

      system.autoUpgrade.allowReboot = true;
      system.autoUpgrade.rebootWindow = {
        lower = "04:00";
        upper = "05:00";
      };
    };
  };
}
