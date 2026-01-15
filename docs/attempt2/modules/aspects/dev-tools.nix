# Development tools aspect
# Shared developer tooling across machines
{ ... }:
{
  den.aspects.dev-tools = {
    homeManager = { pkgs, ... }: {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      programs.starship = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.fzf = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.bat.enable = true;
      programs.eza.enable = true;

      home.packages = with pkgs; [
        lazygit
        delta # Better git diffs
        tokei # Code statistics
        just # Task runner
      ];
    };
  };
}
