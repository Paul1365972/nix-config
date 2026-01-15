{ ... }:
{
  flake.modules.homeManager.dev-tools = { pkgs, ... }: {
    home.packages = with pkgs; [
      neofetch
      helix
      ripgrep
      nushell
      fd
      tree
      unzip
      zip
      ncdu
    ];

    home.sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
    };
  };
}
