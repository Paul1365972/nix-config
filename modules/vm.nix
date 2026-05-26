# `nix run .#vm` boots the phos config in QEMU for live testing without rebooting the host.
{ inputs, ... }:
{
  # Make phos bootable as VM
  den.aspects.phos.nixos =
    { modulesPath, ... }:
    {
      imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix") ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.vm = pkgs.writeShellApplication {
        name = "vm";
        text = ''
          ${inputs.self.nixosConfigurations.phos.config.system.build.vm}/bin/run-phos-vm "$@"
        '';
      };
    };
}
