_: {
  den.aspects.saber.provides.element = {
    nixos = { pkgs, ... }: {
      services.caddy.virtualHosts."http://chat.paul.moe".extraConfig = ''
        header {
          Content-Security-Policy "frame-ancestors 'self'"
          X-Frame-Options SAMEORIGIN
          X-Content-Type-Options nosniff
        }
        root * ${pkgs.element-web}
        file_server
        try_files {path} /index.html
      '';
      services.homepage-dashboard.entries.Element = {
        description = "Matrix chat client";
        href = "https://chat.paul.moe";
        icon = "element.svg";
      };
      nixpkgs.config.element-web.conf = {
        default_server_config."m.homeserver" = {
          base_url = "https://matrix.paul.moe";
          server_name = "matrix.paul.moe";
        };
        brand = "Homeserver paul.moe";
        disable_custom_urls = true;
        disable_guests = true;
      };
    };
  };
}
