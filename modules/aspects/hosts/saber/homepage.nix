{ ... }:
{
  den.aspects.saber.provides.homepage = {
    nixos = {
      services.homepage-dashboard = {
        enable = true;
        # 8082 collides with traccar.
        listenPort = 8088;
        allowedHosts = "1365972.xyz";

        services = [
          {
            "Infra" = [
              {
                "Authentik" = {
                  description = "SSO / identity";
                  href = "https://authentik.1365972.xyz";
                  icon = "authentik.svg";
                };
              }
            ];
          }
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
                  href = "https://matrix-admin.1365972.xyz";
                  icon = "matrix.svg";
                };
              }
              {
                "Maubot" = {
                  description = "Matrix bots";
                  href = "https://maubot.1365972.xyz";
                  icon = "matrix.svg";
                };
              }
              {
                "Traccar" = {
                  description = "GPS tracking";
                  href = "https://traccar.1365972.xyz";
                  icon = "traccar.svg";
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
    };
  };
}
