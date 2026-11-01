{ den, ... }:
{
  # Fallback next to Tailscale SSH: reachable over the LAN when tailscaled is down.
  den.aspects.openssh = {
    includes = [ den.aspects.hardening ];
    nixos = {
      services.openssh = {
        enable = true;
        openFirewall = false;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };
      networking.firewall.extraInputRules = ''
        ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } tcp dport 22 accept
        ip6 saddr { fe80::/10, fc00::/7 } tcp dport 22 accept
      '';
    };
  };
}
