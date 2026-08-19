{ ... }:
{
  den.aspects.saber.provides.hardware = {
    nixos =
      { pkgs, ... }:
      {
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        boot.initrd.availableKernelModules = [
          "xhci_pci"
          "ahci"
          "usb_storage"
          "sd_mod"
        ];
        boot.kernelModules = [ "kvm-intel" ];

        hardware.cpu.intel.updateMicrocode = true;

        # VAAPI/QSV drivers for Jellyfin hardware transcoding on the iGPU.
        hardware.graphics = {
          enable = true;
          extraPackages = [ pkgs.intel-media-driver ];
        };

        environment.systemPackages = [ pkgs.libva-utils ];

        users.users.jellyfin.extraGroups = [ "render" ];

        # Laptop chassis running as a server — keep going when the lid is closed.
        services.logind.settings.Login = {
          HandleLidSwitch = "ignore";
          HandleLidSwitchExternalPower = "ignore";
          HandleLidSwitchDocked = "ignore";
        };
      };
  };
}
