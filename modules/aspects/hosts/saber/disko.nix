{ inputs, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.saber.provides.disko = {
    nixos = {
      imports = [ inputs.disko.nixosModules.disko ];

      # System SSD by serial; sdX letters flip on this machine. The 1TB data disk must never be touched.
      disko.devices.disk.main = {
        device = "/dev/disk/by-id/ata-SanDisk_SD8SNAT-256G-1006_164330427795";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "8G";
              content.type = "swap";
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
