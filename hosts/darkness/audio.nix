{ den, ... }:
{
  den.aspects.darkness.provides.audio = {
    includes = [ den.aspects.audio ];

    homeManager = {
      xdg.configFile = {
        "pipewire/pipewire.conf.d/50-usb-audio-4ch.conf".source =
          ./config/pipewire/pipewire.conf.d/50-usb-audio-4ch.conf;
        "pipewire/client.conf.d/20-upmix.conf".source = ./config/pipewire/client.conf.d/20-upmix.conf;
        "pipewire/pipewire-pulse.conf.d/20-upmix.conf".source =
          ./config/pipewire/pipewire-pulse.conf.d/20-upmix.conf;
      };

      home.file.".asoundrc".source = ./config/asoundrc;
    };
  };
}
