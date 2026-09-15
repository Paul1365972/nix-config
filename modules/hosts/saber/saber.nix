{ den, ... }:
{
  den.hosts.x86_64-linux.saber.users.paul = { };
  den.aspects.saber.includes = with den.aspects.saber.provides; [
    den.aspects.common
    den.aspects.comin
    den.aspects.auto-reboot
    den.aspects.hardening
    den.aspects.network-performance
    den.aspects.tailscale
    den.aspects.openssh
    postgresql
    backup
    caddy
    matrix
    element
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
}
