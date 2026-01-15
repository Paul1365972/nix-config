{ inputs, den, ... }:
{
  den.aspects.phos-wsl = {
    includes = [
      den.aspects.common
      den.aspects.binfmt
    ];

    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.nixos-wsl.nixosModules.default ];

        wsl.enable = true;
        wsl.defaultUser = "paul";
        wsl.interop.register = true;

        environment.systemPackages = with pkgs; [
          wget
          git
          curl
        ];
      };
  };
}
