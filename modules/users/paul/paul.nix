{ den, ... }:
{
  den.aspects.paul = {
    includes = [
      den.batteries.primary-user
      den.batteries.host-aspects
      (den.batteries.user-shell "bash")
      den.aspects.helix
      den.aspects.yazi
      den.aspects.ssh
    ];

    provides = {
      phos.includes = [ den.aspects.workstation-user ];
      phos-wsl = { user, ... }: {
        includes = [ den.aspects.workstation-user ];
        nixos.wsl.defaultUser = user.userName;
      };
    };

    nixos.sops.secrets.user-password.neededForUsers = true;

    user =
      { osConfig, ... }:
      {
        hashedPasswordFile =
          if osConfig.sops.secrets ? user-password then osConfig.sops.secrets.user-password.path else null;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          htop
          ripgrep
          fd
        ];

        programs.git = {
          enable = true;
          settings.user = {
            name = "Paul1365972";
            email = "paul1365972@gmail.com";
          };
        };
      };
  };
}
