# User aspect: paul
# This defines user-specific configurations shared across all hosts
{ den, ... }:
{
  den.aspects.paul = {
    # Include other aspects that this user needs
    includes = [
      # Make paul an administrator on all hosts
      den.provides.primary-user
      # Set default shell
      (den.provides.user-shell "fish")
      # Include shared aspects
      den.aspects.helix
      den.aspects.dev-tools
    ];

    # NixOS configuration for this user (applied to hosts paul lives on)
    nixos = { pkgs, ... }: {
      users.users.paul = {
        description = "Paul";
        extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
      };
    };

    # Home Manager configuration (applied everywhere this user exists)
    homeManager = { pkgs, ... }: {
      programs.git = {
        enable = true;
        userName = "Paul";
        # userEmail = "paul@example.com";
      };

      programs.fish.enable = true;

      home.packages = with pkgs; [
        ripgrep
        fd
        jq
        htop
      ];
    };
  };
}
