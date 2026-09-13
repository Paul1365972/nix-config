{ inputs, lib, ... }:
{
  den.aspects.phos.nixos = {
    virtualisation.vmVariant = {
      disko.enableConfig = false;

      sops.age.keyFile = lib.mkForce null;
      sops.secrets = lib.mkForce { };
      users.users.paul.initialPassword = "phos";

      virtualisation = {
        memorySize = 4096;
        cores = 4;
        qemu.options = [
          "-device virtio-vga-gl"
          "-display sdl,gl=on"
        ];
      };
    };
  };

  perSystem =
    { pkgs, system, ... }:
    lib.mkIf (system == "x86_64-linux") {
      packages.vm = pkgs.writeShellApplication {
        name = "vm";
        text = ''
          ${inputs.self.nixosConfigurations.phos.config.system.build.vm}/bin/run-phos-vm "$@"
        '';
      };
    };
}
