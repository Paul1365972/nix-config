{ den, lib, ... }:
{
  # WiFi and Bluetooth networking
  den.aspects.media-server._.wireless =
    { user, ... }:
    {
      nixos =

        {
          # WiFi via NetworkManager (disable wpa_supplicant)
          networking.networkmanager.enable = true;
          networking.wireless.enable = lib.mkForce false;

          # Bluetooth
          hardware.bluetooth.enable = true;
          services.blueman.enable = true;

          # SSH access
          services.openssh.enable = true;
          users.users.${user.userName}.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEExkUZoKMEE0mf5JY0gcFJEYj+wUCk+k+s1NY7rlhdR paul@phos"
          ];
        };
    };
}
