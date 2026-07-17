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
            hash = "sha256-pNIRthmPf+J6BPfJ51afBCWt66evnRs1+f9wv09EvK0=";
          };

          globalConfig = ''
            email paul@1365972.xyz
            acme_dns cloudflare {env.CF_API_TOKEN}
          '';

          # Imported by every vhost that should sit behind Authentik forward-auth.
          extraConfig = ''
            (authentik) {
              reverse_proxy /outpost.goauthentik.io/* http://127.0.0.1:9000
              forward_auth http://127.0.0.1:9000 {
                uri /outpost.goauthentik.io/auth/caddy
                copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version
                trusted_proxies private_ranges
              }
            }
          '';

          virtualHosts = {
            "1365972.xyz".extraConfig = ''
              import authentik
              reverse_proxy http://127.0.0.1:8088
            '';

            "authentik.1365972.xyz".extraConfig = ''
              reverse_proxy http://127.0.0.1:9000
            '';

            "matrix.1365972.xyz".extraConfig = ''
              reverse_proxy http://127.0.0.1:8008
            '';

            "chat.1365972.xyz".extraConfig = ''
              root * ${pkgs.element-web}
              file_server
              try_files {path} /index.html
            '';

            "matrix-admin.1365972.xyz".extraConfig = ''
              import authentik
              root * ${pkgs.synapse-admin}
              file_server
              try_files {path} /index.html
            '';

            "maubot.1365972.xyz".extraConfig = ''
              reverse_proxy http://127.0.0.1:29316
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

            "traccar.1365972.xyz".extraConfig = ''
              reverse_proxy http://127.0.0.1:8082
            '';

            "home.1365972.xyz".extraConfig = ''
              reverse_proxy http://127.0.0.1:8123
            '';

            "zigbee.1365972.xyz".extraConfig = ''
              import authentik
              reverse_proxy http://127.0.0.1:8089
            '';
          };
        };

        systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.caddy-env.path;
      };
  };
}
