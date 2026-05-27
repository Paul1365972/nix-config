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

        # Intel HD Graphics 620 — VAAPI/QSV for Jellyfin hardware transcoding.
        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            intel-vaapi-driver
            libvdpau-va-gl
            intel-compute-runtime
          ];
        };

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
