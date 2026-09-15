{ inputs, ... }:
{
  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [ (inputs.treefmt-nix.flakeModule or { }) ];

  perSystem.treefmt = {
    settings.global.excludes = [ "references/**" ];
    settings.formatter = {
      deadnix.priority = 1;
      statix.priority = 2;
      nixfmt.priority = 3;
    };
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
    programs.deadnix.enable = true;
    programs.statix.enable = true;
  };
}
