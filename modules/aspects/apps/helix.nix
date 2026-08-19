{ ... }:
{
  den.aspects.helix.homeManager = {
    programs.helix = {
      enable = true;

      languages = {
        language-server.nixd = {
          command = "nixd";
          config.nixd.formatting.command = [ "nixfmt" ];
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
