# enables `nix run .#vm`. it is very useful to have a VM
# you can edit your config and launch the VM to test stuff
# instead of having to reboot each time.
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
