{ inputs, ... }:
{
  flake-file.inputs.authentik-nix = {
    url = "github:nix-community/authentik-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.saber.provides.authentik = {
    nixos =
      { config, lib, ... }:
      let
        socketEnv = {
          AUTHENTIK_POSTGRESQL__HOST = "/run/postgresql";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_REDIS__HOST = "/run/redis-authentik/redis.sock";
        };
      in
      {
        imports = [ inputs.authentik-nix.nixosModules.default ];

        services.authentik = {
          enable = true;
          environmentFile = config.sops.secrets.authentik-env.path;
          # The module would otherwise provision its own postgres role + DB; we use the shared host postgres via peer auth.
          createDatabase = false;
          settings = {
            email.from = "authentik@1365972.xyz";
            disable_startup_analytics = true;
            avatars = "initials";
          };
        };

        # authentik-nix runs the units with DynamicUser=true so we route group access via SupplementaryGroups, not users.users.
        systemd.services = lib.genAttrs [ "authentik" "authentik-worker" "authentik-migrate" ] (_: {
          environment = socketEnv;
          serviceConfig.SupplementaryGroups = [
            "keys"
            "redis-authentik"
          ];
        });

        sops.secrets.authentik-env = {
          sopsFile = inputs.self + "/secrets/saber.yaml";
          group = "keys";
          mode = "0440";
          restartUnits = [
            "authentik.service"
            "authentik-worker.service"
          ];
        };
      };
  };
}
