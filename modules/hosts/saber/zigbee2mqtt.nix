{ inputs, ... }:
{
  den.aspects.saber.provides.zigbee2mqtt.nixos =
    { config, ... }:
    {
      services.zigbee2mqtt = {
        enable = true;
        settings = {
          homeassistant.enabled = true;
          permit_join = false;

          mqtt = {
            base_topic = "zigbee2mqtt";
            server = "mqtt://127.0.0.1:1883";
          };

          # ZBDongle-E V2 ("Dongle Plus V2") uses EFR32MG21; the P variant with CC2652 needs adapter = "zstack".
          serial = {
            port = "/dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_V2_2297930aebf3ef11b084ba1b6d9880ab-if00-port0";
            adapter = "ember";
          };

          frontend = {
            host = "127.0.0.1";
            port = 8089;
          };

          advanced = {
            log_level = "info";
            # Changing this after pairing forces every device to re-join.
            channel = 25;
          };

          availability = true;
        };
      };

      # The network key rides in as ZIGBEE2MQTT_CONFIG_ADVANCED_NETWORK_KEY; changing it also forces every device to re-join.
      sops.secrets.zigbee-env = {
        sopsFile = inputs.self + "/secrets/saber.yaml";
        restartUnits = [ "zigbee2mqtt.service" ];
      };
      systemd.services.zigbee2mqtt.serviceConfig.EnvironmentFile = config.sops.secrets.zigbee-env.path;

      services.tailscale.serve.services.zigbee.endpoints."tcp:443" = "http://127.0.0.1:8089";
    };
}
