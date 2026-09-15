{ den, inputs, ... }:
{
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/nixos-wsl";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-compat.follows = "";
  };

  den.hosts.x86_64-linux.phos-wsl = {
    users.paul = { };
  };

  den.aspects.phos-wsl = {
    includes = with den.aspects; [
      common
      comin
      binfmt
      nix-development
      rust
    ];

    nixos = {
      imports = [ inputs.nixos-wsl.nixosModules.default ];
      wsl.enable = true;
      wsl.interop.register = true;
    };
  };
}
