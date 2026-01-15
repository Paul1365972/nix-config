{ den, lib, ... }:
{
  # WiFi and Bluetooth networking
  den.aspects.media-server._.wireless = {
    nixos = {
      # WiFi via NetworkManager (disable wpa_supplicant)
      networking.networkmanager.enable = true;
      networking.wireless.enable = lib.mkForce false;

      # Bluetooth
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    };
  };
}
