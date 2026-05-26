{ den, ... }:
{
  den.aspects.paul = {
    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "bash")
      den.aspects.helix
      den.aspects.yazi
      den.aspects.nh
      den.aspects.ssh
    ];

    nixos =
      { config, ... }:
      {
        sops.secrets.user-password.neededForUsers = true;
        users.users.paul.hashedPasswordFile = config.sops.secrets.user-password.path;
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
