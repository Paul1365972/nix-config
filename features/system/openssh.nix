_: {
  # Fallback next to Tailscale SSH: reachable over the LAN when tailscaled is down.
  den.aspects.openssh.nixos.services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
