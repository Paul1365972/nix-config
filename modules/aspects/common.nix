{ den, ... }:
{
  # Common NixOS settings shared across hosts
  den.aspects.common = {
    includes = [ den.aspects.nix ];

    nixos =
      { pkgs, ... }:
      {
        # Allow unfree packages
        nixpkgs.config.allowUnfree = true;

        # Timezone and locale
        time.timeZone = "Europe/Amsterdam";
        i18n.defaultLocale = "en_US.UTF-8";

        # Common packages
        environment.systemPackages = with pkgs; [
          vim
          git
          curl
          wget
        ];
      };
  };
}
