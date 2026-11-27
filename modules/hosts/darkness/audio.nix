{ den, ... }:
{
  den.aspects.darkness.provides.audio = {
    includes = [ den.aspects.audio ];

    nixos =
      { pkgs, ... }:
      let
        pinSoundCardMixer = pkgs.writeShellScript "pin-sound-card-mixer" ''
          ${pkgs.alsa-utils}/bin/amixer -q -c "$1" -s <<'EOF'
          cset name='Speaker Playback Switch' on
          cset name='Speaker Playback Volume' 197,197,197,197,197,197,197,197
          cset name='PCM Capture Source' 'Mic'
          cset name='PCM Capture Switch' on
          cset name='PCM Capture Volume' 4096,4096
          cset name='Mic Capture Switch' on
          cset name='Mic Capture Volume' 6928,6928
          cset name='Mic Playback Switch' off
          cset name='Line Playback Switch' off
          cset name='Line Capture Switch' off
          EOF
        '';
        upmix = {
          "channelmix.upmix" = true;
          "channelmix.upmix-method" = "simple";
        };
      in
      {
        services.udev.extraRules = ''
          ACTION=="add|change", SUBSYSTEM=="sound", KERNEL=="controlC*", ENV{ID_VENDOR_ID}=="0d8c", ENV{ID_MODEL_ID}=="0102", RUN+="${pinSoundCardMixer} %n"
        '';

        services.pipewire = {
          extraConfig = {
            client."20-upmix"."stream.properties" = upmix;
            pipewire-pulse."20-upmix"."stream.properties" = upmix;
          };

          wireplumber.extraConfig."50-sound-card" = {
            "wireplumber.settings" = {
              "device.restore-profile" = false;
            };

            "monitor.alsa.rules" = [
              {
                matches = [ { "device.name" = "~alsa_card\\.platform-.*\\.hdmi"; } ];
                actions.update-props."device.disabled" = true;
              }
              {
                matches = [ { "device.name" = "alsa_card.usb-0d8c_USB_Sound_Device-00"; } ];
                actions.update-props = {
                  "device.profile" = "output:analog-surround-40+input:analog-stereo";
                  "api.alsa.soft-mixer" = true;
                };
              }
              {
                matches = [
                  { "node.name" = "alsa_output.usb-0d8c_USB_Sound_Device-00.analog-surround-40"; }
                ];
                actions.update-props = upmix // {
                  "node.description" = "USB Audio 4.0";
                  "channelmix.normalize" = true;
                };
              }
            ];
          };
        };
      };
  };
}
