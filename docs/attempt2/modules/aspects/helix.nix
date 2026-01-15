# Helix editor aspect
# Shared between laptop and WSL - define once, include where needed
{ ... }:
{
  den.aspects.helix = {
    # Home Manager configuration for helix
    homeManager = { pkgs, ... }: {
      programs.helix = {
        enable = true;
        defaultEditor = true;

        settings = {
          theme = "gruvbox";
          editor = {
            line-number = "relative";
            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            lsp.display-messages = true;
            indent-guides.render = true;
          };
        };

        languages = {
          language = [
            {
              name = "nix";
              auto-format = true;
              formatter.command = "nixfmt";
            }
          ];
        };
      };

      home.packages = with pkgs; [
        nixfmt-rfc-style
        nil # Nix LSP
      ];
    };
  };
}
