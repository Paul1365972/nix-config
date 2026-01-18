{ den, ... }:
{
  den.aspects.nix-dev = {
    nixos =
      { pkgs, ... }:
      {
        # Enable nix-ld for VS Code Remote compatibility
        programs.nix-ld.enable = true;

        # Development tools
        environment.systemPackages = with pkgs; [
          nixd 
          nixfmt
          nixfmt-tree
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        # direnv for auto-loading dev environments
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
  };
}
