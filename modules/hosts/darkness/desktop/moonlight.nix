_: {
  den.aspects.darkness.provides.desktop = {
    nixos = {
      # Moonlight finds hosts over mDNS, whose multicast replies connection tracking can't admit.
      networking.firewall.extraInputRules = ''
        ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } udp dport 5353 accept
        ip6 saddr fe80::/10 udp dport 5353 accept
      '';
    };

    homeManager =
      { pkgs, lib, ... }:
      let
        moonlight = lib.getExe pkgs.moonlight-qt;
        graphicalSessionUnit = {
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
      in
      {
        systemd.user.services.moonlight = {
          Unit = graphicalSessionUnit // {
            Description = "Moonlight";
          };
          Service.ExecStart = moonlight;
        };

        # Both instances rewrite the shared host list, pairing certificates included.
        systemd.user.services.moonlight-stream = {
          Unit = graphicalSessionUnit // {
            Description = "Stream phos";
            Conflicts = [ "moonlight.service" ];
            After = graphicalSessionUnit.After ++ [ "moonlight.service" ];
          };
          Service.ExecStart = lib.concatStringsSep " " [
            "${moonlight} stream phos Desktop"
            "--resolution 1280x800 --fps 60 --bitrate 20000"
            # The Pi 5 has no hardware H.264 decoder; probing for one stalls the stream start.
            "--video-codec H.264 --video-decoder software"
            "--display-mode fullscreen --absolute-mouse --capture-system-keys fullscreen"
          ];
        };
      };
  };
}
