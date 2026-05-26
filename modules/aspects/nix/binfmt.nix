{ ... }:
{
  den.aspects.binfmt = {
    nixos = {
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    };
  };
}
