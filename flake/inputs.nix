_: {
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # nixos-* channels gate on the NixOS test jobset, so their revisions are fully built on
  # cache.nixos.org; nixpkgs-unstable runs ahead of it and lands uncached paths.
  flake-file.inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
}
