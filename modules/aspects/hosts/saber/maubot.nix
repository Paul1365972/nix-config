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
              public_url = "https://maubot.1365972.xyz";
              hostname = "127.0.0.1";
              port = 29316;
            };
            plugin_directories = {
              upload = "/var/lib/maubot/plugins";
              load = [ "/var/lib/maubot/plugins" ];
              trash = "/var/lib/maubot/trash";
            };
          };
        };
      };
  };
}
