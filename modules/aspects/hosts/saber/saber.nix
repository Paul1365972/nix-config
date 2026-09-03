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
      caddy
      matrix
      element
      # matrix-bridges: off until the Matrix revamp, re-enable then
      maubot
      nextcloud
      jellyfin
      traccar
      mosquitto
      zigbee2mqtt
      home-assistant
      homepage
      cloudflare-ddns
      cliproxyapi
    ];

    nixos =
      { config, lib, ... }:
      let
        tailscale = lib.getExe config.services.tailscale.package;
        serve =
          name: key: target:
          let
            port = lib.removePrefix "tcp:" key;
            listener = if lib.hasPrefix "tcp://" target then "--tcp=${port}" else "--https=${port}";
          in
          "${tailscale} serve --service=svc:${name} ${listener} ${target}";
      in
      {
        services.tailscale.extraUpFlags = [ "--advertise-exit-node" ];
        # --advertise-exit-node only works if the kernel forwards packets; useRoutingFeatures = "server" sets the v4/v6 forward sysctls.
        services.tailscale.useRoutingFeatures = "server";

        services.tailscale.serve.enable = true;
        # The serve config file cannot express an HTTPS listener in front of an HTTP backend
        # (tailscale/tailscale#18381), so the same endpoints are applied through the CLI instead.
        systemd.services.tailscale-serve.serviceConfig.ExecStart = lib.mkForce (
          [ "${tailscale} serve reset" ]
          ++ lib.concatLists (
            lib.mapAttrsToList (
              name: svc: lib.mapAttrsToList (serve name) svc.endpoints
            ) config.services.tailscale.serve.services
          )
        );
      };
  };
}
