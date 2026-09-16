{
  den.aspects.saber.provides.homepage.nixos =
    { config, lib, ... }:
    {
      options.services.homepage-dashboard.entries = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        default = { };
        description = "Dashboard entries contributed by services.";
      };
      config = {
        services.homepage-dashboard = {
          enable = true;
          listenPort = 8088;
          allowedHosts = "dashboard.echidna-ghost.ts.net";
          services = [
            {
              Apps = lib.mapAttrsToList (name: entry: {
                ${name} = entry;
              }) config.services.homepage-dashboard.entries;
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
        services.tailscale.serve.services.dashboard.endpoints."tcp:443" = "http://127.0.0.1:8088";
      };
    };
}
