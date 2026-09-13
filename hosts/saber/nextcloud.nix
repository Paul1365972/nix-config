{ inputs, ... }:
{
  den.aspects.saber.provides.nextcloud = {
    nixos =
      { config, pkgs, ... }:
      {
        services.nextcloud = {
          enable = true;
          package = pkgs.nextcloud33;
          hostName = "nextcloud.1365972.xyz";
          # TLS is terminated by Caddy; flips $HTTPS in the FastCGI params so Nextcloud generates https:// URLs.
          https = true;
          configureRedis = true;
          appstoreEnable = true;
          maxUploadSize = "2G";

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
