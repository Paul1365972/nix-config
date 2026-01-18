{ den, ... }:
{
  # 4-channel USB audio setup with PipeWire
  den.aspects.media-server._.audio = {
    nixos = {
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    };

    homeManager = {
      xdg.configFile = {
        "pipewire/pipewire.conf.d/50-usb-audio-4ch.conf".source =
          ./config/pipewire/pipewire.conf.d/50-usb-audio-4ch.conf;
        "pipewire/client.conf.d/20-upmix.conf".source = ./config/pipewire/client.conf.d/20-upmix.conf;
      };

      home.file.".asoundrc".source = ./config/asoundrc;
    };
  };
}
