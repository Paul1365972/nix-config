{ ... }:
{
  den.aspects.saber.provides.maubot = {
    nixos =
      { pkgs, ... }:
      {
        services.maubot = {
          enable = true;
          # E2EE would pull in the insecure libolm
          package = pkgs.maubot.override { encryptionSupport = false; };
          settings = {
            database = "postgresql:///maubot?host=/run/postgresql";
            server = {
              public_url = "https://maubot.echidna-ghost.ts.net";
              hostname = "127.0.0.1";
              port = 29316;
            };
            admins.paul = "$2b$10$NDBn0mi32Oe0D29b78HxHeiFxaIiXiStrpXkY/4gXNTWdZh8/trJq";
            plugin_directories = {
              upload = "/var/lib/maubot/plugins";
              load = [ "/var/lib/maubot/plugins" ];
              trash = "/var/lib/maubot/trash";
            };
          };
        };

        services.tailscale.serve.services.maubot.endpoints."tcp:443" = "http://127.0.0.1:29316";
      };
  };
}
