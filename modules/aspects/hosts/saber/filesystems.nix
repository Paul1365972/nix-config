{ ... }:
{
  den.aspects.saber.provides.filesystems = {
    nixos = {
      # WDC 1TB data disk — preserved across reinstalls; disko only manages the system SSD.
      fileSystems."/mnt/hdd" = {
        device = "/dev/disk/by-uuid/413e4787-ab72-4842-8b80-205b6e134756";
        fsType = "ext4";
        options = [
          "defaults"
          "nofail"
        ];
      };

      fileSystems."/var/lib/jellyfin/media" = {
        device = "/mnt/hdd/media";
        fsType = "none";
        options = [ "bind" ];
        depends = [ "/mnt/hdd" ];
      };

      fileSystems."/var/lib/matrix-synapse/media_store" = {
        device = "/mnt/hdd/matrix-media";
        fsType = "none";
        options = [ "bind" ];
        depends = [ "/mnt/hdd" ];
      };
    };
  };
}
