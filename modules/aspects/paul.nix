{
  __findFile,
  den,
  ...
}:
{
  den.aspects.paul = {
    includes = [
      <den/primary-user>
      (<den/user-shell> "bash")
    ];

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
