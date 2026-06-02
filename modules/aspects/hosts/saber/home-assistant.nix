{ ... }:
{
  den.aspects.saber.provides.home-assistant = {
    nixos = {
      # HA won't create these on first boot, but the !include entries below dereference them at startup.
      systemd.tmpfiles.rules = [
        "f /var/lib/hass/automations.yaml 0644 hass hass - []"
        "f /var/lib/hass/scripts.yaml    0644 hass hass - {}"
        "f /var/lib/hass/scenes.yaml     0644 hass hass - []"
      ];

      services.home-assistant = {
        enable = true;
        configDir = "/var/lib/hass";

        extraComponents = [
          "default_config"
          "met"
          "radio_browser"
          "mqtt"
          "esphome"
          "zha"
        ];

        config = {
          default_config = { };

          http = {
            server_host = "127.0.0.1";
            use_x_forwarded_for = true;
            trusted_proxies = [ "127.0.0.1" ];
          };

          homeassistant = {
            name = "Home";
            time_zone = "Europe/Berlin";
            country = "DE";
            unit_system = "metric";
          };

          # Space-suffix keys let HA merge these YAML-file backed sections with the declarative one above.
          "automation ui" = "!include automations.yaml";
          "script ui" = "!include scripts.yaml";
          "scene ui" = "!include scenes.yaml";
        };
      };
    };
  };
}
