{ inputs, ... }:
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.sops.nixos = {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    sops.age.keyFile = "/var/lib/sops-nix/key.txt";
    sops.defaultSopsFile = inputs.self + "/secrets/common.yaml";
  };
}
