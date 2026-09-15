{ inputs, lib, ... }:
let
  publicKeys = (builtins.fromTOML (builtins.readFile (inputs.self + "/secrets/public.toml"))).ssh;
in
{
  den.aspects.ssh =
    { user, ... }:
    let
      keys = publicKeys.${user.name};
    in
    {
      user.openssh.authorizedKeys.keys = [ keys.phos ];

      homeManager.home.file = lib.mapAttrs' (
        name: key: lib.nameValuePair ".ssh/${name}.pub" { text = "${key}\n"; }
      ) keys;
    };

  den.aspects.ssh-identities = { user, ... }: {
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
          owner = user.userName;
          mode = "0400";
        });

    homeManager = {
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
