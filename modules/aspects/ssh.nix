{ inputs, lib, ... }:
let
  pub = (builtins.fromTOML (builtins.readFile (inputs.self + "/secrets/public.toml"))).ssh.paul;
in
{
  den.aspects.ssh = {
    nixos =
      let
        mkKey = name: {
          path = "/home/paul/.ssh/${name}";
          owner = "paul";
          mode = "0600";
        };
      in
      {
        sops.secrets.id_phos = mkKey "id_phos";
        sops.secrets.id_github = mkKey "id_github";
        sops.secrets.geomesh-hetzner = mkKey "geomesh-hetzner";
      };

    homeManager = {
      programs.ssh = {
        enable = true;
        matchBlocks = {
          "github.com".identityFile = "~/.ssh/id_github";
          "geomesh-hetzner 46.224.189.102" = {
            hostname = "46.224.189.102";
            identityFile = "~/.ssh/geomesh-hetzner";
            user = "root";
          };
          "*".identityFile = "~/.ssh/id_phos";
        };
      };

      home.file = lib.mapAttrs' (
        name: key: lib.nameValuePair ".ssh/${name}.pub" { text = "${key}\n"; }
      ) pub;
    };
  };
}
