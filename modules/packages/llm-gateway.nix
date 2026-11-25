{ inputs, lib, ... }:
{
  flake-file.inputs.crane.url = "github:ipetkov/crane";

  perSystem =
    { pkgs, ... }:
    let
      craneLib = inputs.crane.mkLib pkgs;
      root = ../..;
      src = lib.fileset.toSource {
        inherit root;
        fileset = lib.fileset.unions [
          (root + "/Cargo.toml")
          (root + "/Cargo.lock")
          (root + "/crates")
        ];
      };
      common = {
        inherit src;
        inherit (craneLib.crateNameFromCargoToml { cargoToml = root + "/crates/llm-gateway/Cargo.toml"; })
          pname
          version
          ;
        strictDeps = true;
        cargoExtraArgs = "--locked --package llm-gateway";
        doCheck = false;
      };
      cargoArtifacts = craneLib.buildDepsOnly common;
    in
    {
      packages.llm-gateway = craneLib.buildPackage (
        common
        // {
          inherit cargoArtifacts;
          meta.mainProgram = "llm-gateway";
        }
      );
    };
}
