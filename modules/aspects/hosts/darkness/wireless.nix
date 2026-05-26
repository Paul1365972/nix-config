{ den, inputs, ... }:
{
  den.aspects.darkness.provides.wireless = {
    includes = [ den.aspects.bluetooth ];

    nixos =
      { config, ... }:
      {
        networking.wireless.enable = true;

        sops.secrets.wifi-himmel = {
          sopsFile = inputs.self + "/secrets/darkness.yaml";
          group = "wpa_supplicant";
          mode = "0440";
        };
        networking.wireless.secretsFile = config.sops.secrets.wifi-himmel.path;
        networking.wireless.networks.himmel = {
          pskRaw = "ext:HIMMEL_PSK";
          # WPA3-SAE requires PMF.
          extraConfig = "ieee80211w=2";
        };
        networking.wireless.extraConfig = "sae_pwe=2";
      };
  };
}
