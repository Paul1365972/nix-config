{ den, ... }:
{
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/nixos-wsl";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-compat.follows = "";
  };

  den.aspects.phos-wsl = {
    includes = [
      den.aspects.common
      den.aspects.binfmt
      den.aspects.nix-dev
      den.aspects.rust
      den.aspects.comin
    ];

    nixos.wsl.interop.register = true;
  };
}
