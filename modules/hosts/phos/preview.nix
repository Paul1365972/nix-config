{ inputs, lib, ... }:
{
  den.aspects.phos.nixos =
    { modulesPath, ... }:
    {
      image.modules.qemu-efi = {
        imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

        disko.enableConfig = false;
        virtualisation.diskSize = 32 * 1024;
        boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

        services.comin.enable = lib.mkForce false;
        sops.age.keyFile = lib.mkForce null;
        sops.secrets = lib.mkForce { };

        # The first frames over virgl stall long enough for the kernel's realtime watchdog to kill Hyprland.
        environment.sessionVariables.HYPRLAND_NO_RT = "1";
        # The virtio-gpu plane scans out XRGB8888 only, which leaves clients without an alpha format.
        home-manager.sharedModules = [
          {
            wayland.windowManager.hyprland.settings = {
              config.quirks.skip_non_kms_dmabuf_formats = false;
              # QEMU reports a 100 DPI monitor, for which automatic scaling picks 1.
              monitor.scale = lib.mkForce 1.5;
            };
          }
        ];
      };
    };

  perSystem =
    { system, ... }:
    lib.mkIf (system == "x86_64-linux") {
      packages.phos-preview = inputs.self.nixosConfigurations.phos.config.system.build.images.qemu-efi;
    };
}
