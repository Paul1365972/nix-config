{ inputs, ... }:
{
  den.aspects.saber.provides.caddy = {
    nixos =
      {
        config,
        pkgs,
        ...
      }:
      {
        sops.secrets.caddy-env = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          owner = "caddy";
          mode = "0440";
        };

        services.caddy = {
          enable = true;

          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
            hash = "sha256-F7d4HwM4oCkQrFMr4SFSC0r52ONxY+PW6z5BJawW8Ok=";
          };

          globalConfig = ''
            email paul@1365972.xyz
            acme_dns cloudflare {env.CF_API_TOKEN}
          '';

          virtualHosts = {
            "matrix.1365972.xyz".extraConfig = ''
              reverse_proxy http://127.0.0.1:8008
            '';

            "chat.1365972.xyz".extraConfig = ''
              root * ${pkgs.element-web}
              file_server
              try_files {path} /index.html
            '';

            ":8091".extraConfig = ''
              bind 127.0.0.1
              root * ${pkgs.synapse-admin}
              file_server
              try_files {path} /index.html
            '';

            "jellyfin.1365972.xyz".extraConfig = ''
              reverse_proxy http://127.0.0.1:8096
            '';

            # WebDAV CORS so Obsidian (and other 3rd-party clients) can talk to /remote.php/dav/*.
            "nextcloud.1365972.xyz".extraConfig = ''
              @webdav path /remote.php/dav/*
              header @webdav {
                Access-Control-Allow-Origin "{http.request.header.Origin}"
                Access-Control-Allow-Methods "GET, POST, PUT, DELETE, MKCOL, COPY, MOVE, PROPFIND, PROPPATCH, OPTIONS"
                Access-Control-Allow-Headers "Authorization, Content-Type, Depth, If-Match, If-Modified-Since, If-None-Match, Lock-Token, Timeout"
                Access-Control-Allow-Credentials "true"
              }
              @preflight {
                method OPTIONS
                path /remote.php/dav/*
              }
              respond @preflight 204

              reverse_proxy 127.0.0.1:8080
            '';
          };
        };

        services.tailscale.serve.services.matrix-admin.endpoints."tcp:443" = "http://127.0.0.1:8091";

        systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.caddy-env.path;
      };
  };
}
