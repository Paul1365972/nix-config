{
  den.aspects.saber.provides.postgresql.nixos =
    { pkgs, ... }:
    {
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_17;
        identMap = ''
          saber root      all
          saber postgres  all
        '';
      };
    };
}
