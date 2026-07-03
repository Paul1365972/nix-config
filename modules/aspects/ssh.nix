{ inputs, lib, ... }:
let
  pub = (builtins.fromTOML (builtins.readFile (inputs.self + "/secrets/public.toml"))).ssh.paul;
in
{
  den.aspects.ssh = {
    nixos =
      let
        key = {
          owner = "paul";
          mode = "0400";
        };
      in
      {
        sops.secrets.id_phos = key;
        sops.secrets.id_github = key;
        sops.secrets.geomesh-hetzner = key;
      };

    homeManager = {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "github.com".IdentityFile = "/run/secrets/id_github";
          "geomesh-hetzner 46.224.189.102" = {
            HostName = "46.224.189.102";
            IdentityFile = "/run/secrets/geomesh-hetzner";
            User = "root";
          };
          "*".IdentityFile = "/run/secrets/id_phos";
        };
      };

      home.file = lib.mapAttrs' (
        name: key: lib.nameValuePair ".ssh/${name}.pub" { text = "${key}\n"; }
      ) pub;
    };
  };
}
