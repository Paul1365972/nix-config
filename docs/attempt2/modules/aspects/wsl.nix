# WSL host aspect
# This aspect is automatically used by the 'wsl' host (den.hosts.*.wsl)
{ inputs, den, ... }:
{
  den.aspects.wsl = {
    # Include aspects for this host
    includes = [
      # den.aspects.audio # Uncomment if you want audio in WSL
    ];

    nixos = { pkgs, ... }: {
      # Import NixOS-WSL module
      imports = [ inputs.nixos-wsl.nixosModules.default ];

      wsl = {
        enable = true;
        defaultUser = "paul";
        startMenuLaunchers = true;
        interop = {
          register = true;
          includePath = true;
        };
      };

      # Nix settings
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [ "root" "paul" ];
      };

      environment.systemPackages = with pkgs; [
        wget
        curl
        git
      ];
    };

    homeManager = { ... }: {
      home.sessionVariables.TERM = "xterm-256color";
    };
  };
}
