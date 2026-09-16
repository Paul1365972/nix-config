_: {
  den.aspects.saber.provides.element = {
    nixos = { pkgs, ... }: {
      services.caddy.virtualHosts."chat.1365972.xyz".extraConfig = ''
        root * ${pkgs.element-web}
        file_server
        try_files {path} /index.html
      '';
      services.homepage-dashboard.entries.Element = {
        description = "Matrix chat client";
        href = "https://chat.1365972.xyz";
        icon = "element.svg";
      };
      nixpkgs.config.element-web.conf = {
        default_server_config."m.homeserver" = {
          base_url = "https://matrix.1365972.xyz";
          server_name = "matrix.1365972.xyz";
        };
        brand = "Homeserver 1365972";
        disable_custom_urls = true;
        disable_guests = true;
      };
    };
  };
}
