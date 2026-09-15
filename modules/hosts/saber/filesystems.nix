_: {
  den.aspects.saber = {
    nixos = {
      # The 1TB data disk outlives reinstalls; disko manages only the system SSD.
      fileSystems."/mnt/hdd" = {
        device = "/dev/disk/by-uuid/413e4787-ab72-4842-8b80-205b6e134756";
        fsType = "ext4";
        options = [
          "defaults"
          "nofail"
        ];
      };

    };
  };
}
