{ den, ... }:
let
  workstation = [
    den.aspects.ssh-identities
    den.aspects.agents
  ];
in
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
      phos = { user, ... }: {
        includes = workstation;
        nixos = { pkgs, ... }: {
          services.greetd.settings.initial_session = {
            user = user.userName;
            command = "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
          };
          virtualisation.vmVariant.users.users.${user.userName}.initialPassword = "phos";
        };
      };
      phos-wsl = { user, ... }: {
        includes = workstation;
        nixos.wsl.defaultUser = user.userName;
      };
      darkness = { user, ... }: {
        nixos = { pkgs, ... }: {
          services.greetd.settings.default_session = {
            user = user.userName;
            command = "${pkgs.labwc}/bin/labwc";
          };
        };
      };
    };

    nixos.sops.secrets.user-password.neededForUsers = true;

    user =
      { osConfig, ... }:
      {
        hashedPasswordFile = osConfig.sops.secrets.user-password.path or null;
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
