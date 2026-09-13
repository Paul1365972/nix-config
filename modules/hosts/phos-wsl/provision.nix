{ inputs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    let
      builder = inputs.self.nixosConfigurations.phos-wsl.config.system.build.tarballBuilder;
    in
    {
      packages.provision-phos-wsl = pkgs.writeShellApplication {
        name = "provision-phos-wsl";
        runtimeInputs = [ config.packages.host-key ];
        text = ''
          out="''${1:-result-phos-wsl.tar.gz}"
          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT
          install -d -m 0700 "$tmp/extra/var/lib/sops-nix"
          host-key phos-wsl | install -m 0600 /dev/stdin "$tmp/extra/var/lib/sops-nix/key.txt"
          sudo ${builder}/bin/nixos-wsl-tarball-builder \
            --extra-files "$tmp/extra" --chown /var/lib/sops-nix/key.txt 0:0 "$out"
          sudo chown "$(id -u):$(id -g)" "$out"
          echo "-> $out"
        '';
      };
    };
}
