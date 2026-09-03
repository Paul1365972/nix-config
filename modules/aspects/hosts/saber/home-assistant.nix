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

          homeassistant = {
            name = "Home";
            time_zone = "Europe/Berlin";
            country = "DE";
            unit_system = "metric";
            auth_providers = [
              { type = "homeassistant"; }
              {
                type = "trusted_networks";
                trusted_networks = [
                  "100.64.0.0/10"
                  "fd7a:115c:a1e0::/48"
                ];
                allow_bypass_login = true;
              }
            ];
          };

          # Space-suffix keys let HA merge these YAML-file backed sections with the declarative one above.
          "automation ui" = "!include automations.yaml";
          "script ui" = "!include scripts.yaml";
          "scene ui" = "!include scenes.yaml";
        };
      };

      services.tailscale.serve.services.home-assistant.endpoints."tcp:443" = "http://127.0.0.1:8123";
    };
  };
}
