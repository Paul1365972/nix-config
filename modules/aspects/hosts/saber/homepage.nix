{ ... }:
{
  den.aspects.saber.provides.homepage = {
    nixos = {
      services.homepage-dashboard = {
        enable = true;
        # 8082 collides with traccar.
        listenPort = 8088;
        allowedHosts = "dashboard.echidna-ghost.ts.net";

        services = [
          {
            "Apps" = [
              {
                "Jellyfin" = {
                  description = "Media";
                  href = "https://jellyfin.1365972.xyz";
                  icon = "jellyfin.svg";
                };
              }
              {
                "Nextcloud" = {
                  description = "Files / calendar";
                  href = "https://nextcloud.1365972.xyz";
                  icon = "nextcloud.svg";
                };
              }
              {
                "Element" = {
                  description = "Matrix chat client";
                  href = "https://chat.1365972.xyz";
                  icon = "element.svg";
                };
              }
              {
                "Synapse Admin" = {
                  description = "Matrix admin UI";
                  href = "https://matrix-admin.echidna-ghost.ts.net";
                  icon = "matrix.svg";
                };
              }
              {
                "Maubot" = {
                  description = "Matrix bots";
                  href = "https://maubot.echidna-ghost.ts.net/_matrix/maubot/";
                  icon = "matrix.svg";
                };
              }
              {
                "Traccar" = {
                  description = "GPS tracking";
                  href = "https://traccar.echidna-ghost.ts.net";
                  icon = "traccar.svg";
                };
              }
              {
                "Home Assistant" = {
                  description = "Smart home";
                  href = "https://home-assistant.echidna-ghost.ts.net";
                  icon = "home-assistant.svg";
                };
              }
              {
                "Zigbee2MQTT" = {
                  description = "Zigbee mesh admin";
                  href = "https://zigbee.echidna-ghost.ts.net";
                  icon = "zigbee2mqtt.svg";
                };
              }
            ];
          }
        ];

        settings = {
          title = "1365972.xyz";
          background = {
            blur = "md";
            opacity = 60;
          };
        };
      };

      services.tailscale.serve.services.dashboard.endpoints."tcp:443" = "http://127.0.0.1:8088";
    };
  };
}
