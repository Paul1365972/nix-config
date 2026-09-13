{ den, ... }:
{
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/nixos-wsl";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-compat.follows = "";
  };

  den.hosts.x86_64-linux.phos-wsl = {
    wsl.enable = true;
    users.paul = { };
  };

  den.aspects.phos-wsl = {
    includes = with den.aspects; [
      common
      comin
      ssh-identities
      agents
      binfmt
      nix-dev
      rust
    ];

    nixos.wsl.interop.register = true;
  };
}
