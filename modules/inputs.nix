# Inputs can be placed in any module, the best practice is to have them
# as close as possible to their actual usage.
# Run `nix run .#write-flake` after changing any input.
{ ... }:
{
  flake-file.inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "";
    };
  };
}
