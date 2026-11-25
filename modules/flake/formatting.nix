{ inputs, ... }:
{
  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [ (inputs.treefmt-nix.flakeModule or { }) ];

  perSystem.treefmt = {
    settings.formatter = {
      deadnix.priority = 1;
      statix.priority = 2;
      nixfmt.priority = 3;
    };
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
    programs.rustfmt = {
      enable = true;
      edition = "2024";
    };
    programs.deadnix.enable = true;
    programs.statix.enable = true;
  };
}
