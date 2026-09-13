{ inputs, lib, ... }:
let
  pub = (builtins.fromTOML (builtins.readFile (inputs.self + "/secrets/public.toml"))).ssh.paul;
in
{
  den.aspects.ssh = {
    nixos.users.users.paul.openssh.authorizedKeys.keys = [ pub.phos ];

    homeManager.home.file = lib.mapAttrs' (
      name: key: lib.nameValuePair ".ssh/${name}.pub" { text = "${key}\n"; }
    ) pub;
  };

  den.aspects.ssh-identities = {
    nixos.sops.secrets =
      lib.genAttrs
        [
          "id_phos"
          "id_github"
          "id_opencode"
          "geomesh-hetzner"
        ]
        (_: {
          sopsFile = inputs.self + "/secrets/workstations.yaml";
          owner = "paul";
          mode = "0400";
        });

    provides.to-users.homeManager = {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "github.com".IdentityFile = "/run/secrets/id_github";
          "gitlab.opencode.de" = {
            IdentityFile = "/run/secrets/id_opencode";
            IdentitiesOnly = true;
          };
          "geomesh-hetzner 178.105.137.230" = {
            HostName = "178.105.137.230";
            IdentityFile = "/run/secrets/geomesh-hetzner";
            User = "root";
          };
          "*".IdentityFile = "/run/secrets/id_phos";
        };
      };

      programs.git = {
        signing = {
          format = "ssh";
          key = "/run/secrets/id_github";
          signByDefault = true;
        };
        settings.init.defaultBranch = "main";
      };
    };
  };
}
