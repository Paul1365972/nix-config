{ ... }:
{
  den.aspects.saber.provides.jellyfin = {
    nixos = {
      services.jellyfin.enable = true;
    };
  };
}
