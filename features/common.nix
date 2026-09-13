{ den, ... }:
{
  den.aspects.common = {
    includes = [
      den.aspects.nix
      den.aspects.nh
      den.aspects.sops
    ];

    nixos =
      { pkgs, lib, ... }:
      {
        nixpkgs.config.allowUnfree = true;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        time.timeZone = lib.mkDefault "Europe/Berlin";
        i18n.defaultLocale = "en_US.UTF-8";

        environment.systemPackages = with pkgs; [
          vim
          git
          curl
          wget

          iw
          usbutils
          pciutils
          lsof
        ];
      };
  };
}
