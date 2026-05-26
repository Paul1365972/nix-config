{ ... }:
{
  den.aspects.nh = {
    nixos =
      { pkgs, ... }:
      {
        programs.nh.enable = true;
        # nh auto-detects nom and pipes build output through it when present.
        environment.systemPackages = [ pkgs.nix-output-monitor ];
      };

    homeManager = {
      programs.nix-your-shell.enable = true;
    };
  };
}
