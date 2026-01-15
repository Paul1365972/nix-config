{ lib, config, inputs, ... }:
let
  cfg = config.flake.hosts;

  mkHost = name: hostCfg:
    inputs.nixpkgs.lib.nixosSystem {
      system = hostCfg.system;

      modules = [
        (inputs.self + "/hardware/${name}.nix")

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;

            users.${hostCfg.user}.imports =
              lib.filter (m: m != null)
                (map (aspect: config.flake.modules.homeManager.${aspect} or null) hostCfg.aspects);
          };
        }
      ] ++ hostCfg.extraModules
        ++ (lib.filter (m: m != null)
            (map (aspect: config.flake.modules.nixos.${aspect} or null) hostCfg.aspects));
    };
in
{
  options.flake.modules.nixos = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = {};
    description = "NixOS aspect modules";
  };

  options.flake.modules.homeManager = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = {};
    description = "Home Manager aspect modules";
  };

  options.flake.hosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        system = lib.mkOption {
          type = lib.types.str;
          description = "System architecture (e.g., x86_64-linux, aarch64-linux)";
        };

        user = lib.mkOption {
          type = lib.types.str;
          description = "Primary user for this host";
        };

        aspects = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "List of aspect names to include (applies to both nixos and homeManager)";
        };

        extraModules = lib.mkOption {
          type = lib.types.listOf lib.types.anything;
          default = [];
          description = "Additional NixOS modules to include (for special cases like nixos-wsl)";
        };
      };
    });
    default = {};
    description = "Declarative host definitions";
  };

  config.flake.nixosConfigurations = lib.mapAttrs mkHost cfg;
}
