# Flake inputs managed via flake-file
# Run `nix run .#write-flake` after changing any input.
{ ... }:
{
  flake-file.inputs = {
    # Home Manager for dotfiles and user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-WSL for running NixOS on Windows Subsystem for Linux
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
