{ inputs, ... }:
{
  den.aspects.saber.provides.nextcloud = {
    nixos =
      {
        config,
        pkgs,
        ...
      }:
      {
        services.homepage-dashboard.entries.Nextcloud = {
          description = "Files / calendar";
          href = "https://nextcloud.1365972.xyz";
          icon = "nextcloud.svg";
        };
        services.borgbackup.jobs.hdd.paths = [ "/var/lib/nextcloud" ];
        systemd.services.borgbackup-job-hdd = {
          conflicts = [
            "nextcloud-cron.timer"
            "nextcloud-cron.service"
            "phpfpm-nextcloud.service"
          ];
          after = [
            "nextcloud-setup.service"
            "nextcloud-update-db.service"
          ];
        };
        services.caddy.virtualHosts."nextcloud.1365972.xyz".extraConfig = ''
          @webdav {
            path /remote.php/dav/*
            header Origin app://obsidian.md
            header Origin capacitor://localhost
            header Origin http://localhost
            header Origin https://localhost
          }
          route @webdav {
            header {
              Access-Control-Allow-Origin "{http.request.header.Origin}"
              Access-Control-Allow-Methods "{http.request.header.Access-Control-Request-Method}"
              Access-Control-Allow-Headers "{http.request.header.Access-Control-Request-Headers}"
              Access-Control-Allow-Credentials true
              +Vary "Origin, Access-Control-Request-Method, Access-Control-Request-Headers"
            }
            @preflight method OPTIONS
            respond @preflight 204
          }

          reverse_proxy 127.0.0.1:8080
        '';
        services.nextcloud = {
          enable = true;
          package = pkgs.nextcloud33;
          hostName = "nextcloud.1365972.xyz";
          # TLS is terminated by Caddy; flips $HTTPS in the FastCGI params so Nextcloud generates https:// URLs.
          https = true;
          configureRedis = true;
          appstoreEnable = true;
          maxUploadSize = "2G";
          database.createLocally = true;

          config = {
            dbtype = "pgsql";
            dbhost = "/run/postgresql";
            dbname = "nextcloud";
            dbuser = "nextcloud";
            adminuser = "admin";
            adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
          };

          settings = {
            trusted_domains = [ "nextcloud.1365972.xyz" ];
            trusted_proxies = [ "127.0.0.1" ];
            overwriteprotocol = "https";
            overwritehost = "nextcloud.1365972.xyz";
          };
        };

        # The module brings up its own nginx; bind to loopback so Caddy can sit in front.
        services.nginx.virtualHosts."nextcloud.1365972.xyz".listen = [
          {
            addr = "127.0.0.1";
            port = 8080;
            ssl = false;
          }
        ];

        # Nextcloud's external storage points at /mnt/hdd/gallery (owned root:users).
        users.users.nextcloud.extraGroups = [ "users" ];

        sops.secrets.nextcloud-admin-pass = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          owner = "nextcloud";
          mode = "0440";
        };
      };
  };
}
