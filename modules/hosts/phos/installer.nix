{ inputs, lib, ... }:
{
  perSystem =
    { system, ... }:
    lib.mkIf (system == "x86_64-linux") {
      packages.installer-iso =
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            (
              { pkgs, ... }:
              {
                environment.systemPackages = with pkgs; [
                  helix
                  sops
                ];
              }
            )
          ];
        }).config.system.build.isoImage;
    };
}
