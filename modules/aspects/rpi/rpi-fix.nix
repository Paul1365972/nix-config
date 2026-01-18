# Workaround for boot.loader.raspberryPi conflict when using standard nixpkgs
# with nixos-raspberrypi modules.
#
# Issue: nixpkgs marks boot.loader.raspberryPi as removed (via rename.nix),
# but nixos-raspberrypi re-adds it, causing a type conflict.
#
# Solution: Disable rename.nix and re-import it with the raspberryPi option filtered out.
# Based on workaround from: https://github.com/nvmd/nixos-raspberrypi/issues/113
{ inputs, den, ... }:
{
  den.aspects.rpi-fix = {
    nixos =
      { lib, ... }:
      let
        nixpkgsPath = inputs.nixpkgs.outPath;
        renamePath = nixpkgsPath + "/nixos/modules/rename.nix";
        renameModule = import renamePath { inherit lib; };
        moduleFilter =
          module:
          lib.attrByPath [ "options" "boot" "loader" "raspberryPi" ] null (module {
            config = null;
            options = null;
          }) == null;
      in
      {
        disabledModules = [ renamePath ];
        imports = builtins.filter moduleFilter renameModule.imports;
      };
  };
}
