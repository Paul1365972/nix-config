# Run `nix run .#write-flake` after changing any input (flake.nix is auto-generated).
{ ... }:
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # `pkgs.stable.<pkg>` available everywhere; see modules/aspects/overlays.nix.
  flake-file.inputs.nixpkgs-stable.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
}
