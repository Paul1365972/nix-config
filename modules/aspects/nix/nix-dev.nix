{ ... }:
{
  den.aspects.nix-dev = {
    nixos =
      { pkgs, ... }:
      {
        # nix-ld lets VS Code Remote (and other glibc-linked downloaded binaries) run.
        programs.nix-ld.enable = true;

        environment.systemPackages = with pkgs; [
          nixd
          nixfmt
          nixfmt-tree
        ];
      };

    homeManager = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
