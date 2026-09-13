{ inputs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    {
      packages.provision-saber = pkgs.writeShellApplication {
        name = "provision-saber";
        runtimeInputs = [
          config.packages.host-key
          pkgs.nixos-anywhere
        ];
        text = ''
          target="''${1:-root@saber}"
          [ "$#" -gt 0 ] && shift
          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT

          install -d -m 0700 "$tmp/var/lib/sops-nix"
          host-key saber | install -m 0600 /dev/stdin "$tmp/var/lib/sops-nix/key.txt"

          nixos-anywhere \
            --flake ${inputs.self}#saber \
            --target-host "$target" \
            --extra-files "$tmp" \
            "$@"
        '';
      };
    };
}
