{ ... }:
{
  # comin switches live but never reboots; this covers kernel updates.
  den.aspects.auto-reboot.nixos = {
    systemd.services.auto-reboot = {
      serviceConfig.Type = "oneshot";
      script = ''
        booted=$(readlink /run/booted-system/kernel /run/booted-system/initrd)
        current=$(readlink /run/current-system/kernel /run/current-system/initrd)
        [ "$booted" = "$current" ] || systemctl reboot
      '';
    };
    systemd.timers.auto-reboot = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 04:30:00";
        RandomizedDelaySec = "15m";
      };
    };
  };
}
