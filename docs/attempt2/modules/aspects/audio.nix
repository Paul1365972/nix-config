# Audio aspect
# Contains both NixOS (system services) and Home Manager (user apps) config
# Include with a single line: den.aspects.audio
{ ... }:
{
  den.aspects.audio = {
    # NixOS: system-level audio configuration
    nixos = { pkgs, ... }: {
      # Enable PipeWire
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      # Disable PulseAudio (we use PipeWire's pulse emulation)
      hardware.pulseaudio.enable = false;

      # Real-time scheduling for audio
      security.rtkit.enable = true;
    };

    # Home Manager: user-level audio tools
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        pavucontrol # PulseAudio volume control GUI
        playerctl # Command-line media player control
      ];
    };
  };
}
