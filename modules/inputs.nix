# Run `nix run .#write-flake` after changing any input (flake.nix is auto-generated).
{ ... }:
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # nixos-* channels gate on the NixOS test jobset, so their revisions are fully built on
  # cache.nixos.org; nixpkgs-unstable runs ahead of it and lands uncached paths.
  flake-file.inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # `pkgs.stable.<pkg>` available everywhere; see modules/aspects/overlays.nix.
  flake-file.inputs.nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
}
