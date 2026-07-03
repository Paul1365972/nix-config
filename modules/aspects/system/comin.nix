{ inputs, ... }:
{
  flake-file.inputs.comin = {
    url = "github:nlewo/comin";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.comin.nixos = {
    imports = [ inputs.comin.nixosModules.comin ];

    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/Paul1365972/nix-config.git";
          branches.main.name = "main";
        }
      ];
    };
  };
}
