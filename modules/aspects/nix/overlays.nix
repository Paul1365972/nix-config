{ inputs, ... }:
{
  den.aspects.overlays.nixos =
    { system, ... }:
    {
      nixpkgs.overlays = [
        (_final: _prev: {
          stable = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
        })
      ];
    };
}
