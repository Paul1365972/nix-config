{ den, ... }:
{
  # 4-channel USB audio setup with PipeWire
  den.aspects.media-server._.audio = {
    nixos = {
      # PipeWire with ALSA
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    };

    homeManager =
      { pkgs, ... }:
      {
        # PipeWire 4-channel USB audio config
        xdg.configFile."pipewire/pipewire.conf.d/50-usb-audio-4ch.conf".text = ''
          context.objects = [
            {
              factory = adapter
              args = {
                factory.name     = api.alsa.pcm.sink
                node.name        = "usb_audio_4ch"
                node.description = "USB Audio 4.0"
                media.class      = Audio/Sink
                api.alsa.path    = "remap40"
                api.alsa.period-size = 1024
                api.alsa.headroom = 0
                audio.format     = S16LE
                audio.rate       = 48000
                audio.channels   = 4
                audio.position   = [ FL FR RL RR ]
                channelmix.upmix = true
                channelmix.normalize = true
                channelmix.lfe-cutoff = 150
              }
            }
          ]
        '';

        # PipeWire upmix config
        xdg.configFile."pipewire/client.conf.d/20-upmix.conf".text = ''
          stream.properties = {
            channelmix.upmix = true
            channelmix.upmix-method = simple
          }
        '';

        # ALSA remap config for 4-channel audio
        home.file.".asoundrc".text = ''
          pcm.remap40 {
            type route
            slave {
              pcm "hw:0"
              channels 8
            }
            ttable.0.0 1.0
            ttable.1.1 1.0
            ttable.2.4 1.0
            ttable.3.5 1.0
          }

          pcm.!default {
            type plug
            slave.pcm "remap40"
          }

          ctl.!default {
            type hw
            card 0
          }
        '';
      };
  };
}
