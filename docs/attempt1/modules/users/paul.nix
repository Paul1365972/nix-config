{ lib, ... }:
let
  userName = "paul";
  userDescription = "Paul";
  homeDirectory = "/home/${userName}";

  fullName = "Paul1365972";
  email = "paul1365972@gmail.com";
in
{
  flake.modules.nixos.paul = { pkgs, ... }: {
    users.users.${userName} = {
      isNormalUser = true;
      description = userDescription;
      extraGroups = [ "networkmanager" "wheel" "input" "video" "audio" ];
      shell = pkgs.zsh;
    };

    programs.zsh.enable = true;
  };

  flake.modules.homeManager.paul = {
    home = {
      username = userName;
      homeDirectory = homeDirectory;
      stateVersion = "25.05";
    };

    programs.home-manager.enable = true;

    programs.git.settings.user = {
      name = lib.mkForce fullName;
      email = lib.mkForce email;
    };
  };
}
