{ inputs, den, ... }:
{
  den.aspects.phos-wsl = {
    includes = [
      den.aspects.common
      den.aspects.binfmt
      den.aspects.nix-dev
    ];

    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.nixos-wsl.nixosModules.default ];

        wsl.enable = true;
        wsl.interop.register = true;

        environment.systemPackages = with pkgs; [
          wget
          git
          curl
        ];
      };
  };
}
