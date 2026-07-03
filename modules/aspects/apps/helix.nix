{ ... }:
{
  den.aspects.helix.homeManager =
    { config, osConfig, ... }:
    let
      # Live flake eval — nixd resolves options from the actually-built system,
      # so completions reflect the current host and its HM users.
      flakePath = "${config.home.homeDirectory}/nix-config";
      getFlake = "(builtins.getFlake \"${flakePath}\")";
      hostOpts = "${getFlake}.nixosConfigurations.${osConfig.networking.hostName}.options";
    in
    {
      programs.helix = {
        enable = true;

        languages = {
          language-server.nixd = {
            command = "nixd";
            config.nixd = {
              formatting.command = [ "nixfmt" ];
              options = {
                nixos.expr = hostOpts;
                home-manager.expr = "${hostOpts}.home-manager.users.type.getSubOptions []";
                flake-parts.expr = "${getFlake}.debug.options";
              };
            };
          };

          language = [
            {
              name = "nix";
              language-servers = [ "nixd" ];
              formatter.command = "nixfmt";
              auto-format = true;
            }
          ];
        };
      };
    };
}
