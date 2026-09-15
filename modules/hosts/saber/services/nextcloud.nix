{ inputs, ... }:
{
  den.aspects.saber.provides.nextcloud = {
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        saber.backup.prepare = [
          (pkgs.writeShellApplication {
            name = "nextcloud-backup-prepare";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.jq
            ];
            text = ''
              state="$1"
              status="$(${lib.getExe config.services.nextcloud.occ} status --output=json)"
              jq -e '.installed == true' <<< "$status" > /dev/null
              if jq -e '.maintenance == false' <<< "$status" > /dev/null; then
                touch "$state/nextcloud-maintenance"
                ${lib.getExe config.services.nextcloud.occ} maintenance:mode --on
              fi
            '';
          })
        ];
        saber.backup.resume = [
          (pkgs.writeShellApplication {
            name = "nextcloud-backup-resume";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              state="$1"
              if [[ -e "$state/nextcloud-maintenance" ]]; then
                ${lib.getExe config.services.nextcloud.occ} maintenance:mode --off
                rm -- "$state/nextcloud-maintenance"
              fi
            '';
          })
        ];
        services.borgbackup.jobs.hdd.paths = [ "/var/lib/nextcloud" ];
        services.borgbackup.jobs.hdd.readWritePaths = [ config.services.nextcloud.home ];
        systemd.services.backup-recovery = {
          wants = [ "nextcloud-setup.service" ];
          after = [ "nextcloud-setup.service" ];
        };
        saber.backup.units = [
          "nextcloud-cron.timer"
          "nextcloud-cron.service"
          "nextcloud-setup.service"
          "nextcloud-update-db.service"
          "phpfpm-nextcloud.service"
        ];
        saber.dashboard.Nextcloud = {
          description = "Files / calendar";
          href = "https://nextcloud.1365972.xyz";
          icon = "nextcloud.svg";
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
