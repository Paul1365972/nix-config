# Provisioning artifacts. Run on a host that already has the master sops key
# at /var/lib/sops-nix/key.txt (i.e. phos or phos-wsl):
#
#   nix run .#installer   -> result-installer.iso        (dd to USB, boot phos for install)
#   nix run .#darkness    -> result-darkness.img         (dd to SD card, key already injected)
#   nix run .#phos-wsl    -> result-phos-wsl.tar.gz      (wsl --import, key already embedded)
#   nix run .#saber -- root@saber                        (nixos-anywhere over kexec, key injected)
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      keyOf =
        host:
        ''SOPS_AGE_KEY="$(sudo cat /var/lib/sops-nix/key.txt)" sops -d --extract '["${host}-age-key"]' ${../secrets/keys.yaml}'';

      installerSystem = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          (
            { pkgs, ... }:
            {
              environment.systemPackages = with pkgs; [
                helix
                sops
              ];
            }
          )
        ];
      };
    in
    {
      packages.installer = pkgs.writeShellApplication {
        name = "build-installer";
        text = ''
          out="''${1:-result-installer.iso}"
          cp ${installerSystem.config.system.build.isoImage}/iso/*.iso "$out"
          chmod 644 "$out"
          echo "-> $out"
        '';
      };

      packages.darkness =
        let
          image = inputs.self.nixosConfigurations.darkness.config.system.build.sdImage;
        in
        pkgs.writeShellApplication {
          name = "provision-darkness";
          runtimeInputs = with pkgs; [
            jq
            sops
            util-linux
            zstd
          ];
          text = ''
            out="''${1:-result-darkness.img}"
            zstd -d -f ${image}/sd-image/*.img.zst -o "$out"
            chmod 644 "$out"
            parts=$(sfdisk -J "$out" | jq -r '.partitiontable.partitions[1] | "\(.start) \(.size)"')
            off=$(( $(echo "$parts" | cut -d' ' -f1) * 512 ))
            len=$(( $(echo "$parts" | cut -d' ' -f2) * 512 ))
            loop=$(sudo losetup -f --show -o "$off" --sizelimit "$len" "$out")
            trap 'sudo umount "$loop" 2>/dev/null || true; sudo losetup -d "$loop"' EXIT
            mnt=$(mktemp -d)
            sudo mount "$loop" "$mnt"
            sudo install -d -m 0700 "$mnt/var/lib/sops-nix"
            ${keyOf "darkness"} | sudo install -m 0600 /dev/stdin "$mnt/var/lib/sops-nix/key.txt"
            sudo umount "$mnt"
            rmdir "$mnt"
            echo "-> $out"
          '';
        };

      packages.saber = pkgs.writeShellApplication {
        name = "provision-saber";
        runtimeInputs = with pkgs; [
          sops
          nixos-anywhere
        ];
        text = ''
          target="''${1:-root@saber}"
          # Shift target off $@ so remaining args pass through to nixos-anywhere.
          [ "$#" -gt 0 ] && shift
          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT

          install -d -m 0700 "$tmp/var/lib/sops-nix"
          ${keyOf "saber"} | install -m 0600 /dev/stdin "$tmp/var/lib/sops-nix/key.txt"

          nixos-anywhere \
            --flake ${inputs.self}#saber \
            --target-host "$target" \
            --extra-files "$tmp" \
            "$@"
        '';
      };

      packages.phos-wsl =
        let
          builder = inputs.self.nixosConfigurations.phos-wsl.config.system.build.tarballBuilder;
        in
        pkgs.writeShellApplication {
          name = "provision-phos-wsl";
          runtimeInputs = with pkgs; [ sops ];
          text = ''
            out="''${1:-result-phos-wsl.tar.gz}"
            tmp=$(mktemp -d)
            trap 'rm -rf "$tmp"' EXIT
            install -Dm600 <(${keyOf "phos-wsl"}) "$tmp/extra/var/lib/sops-nix/key.txt"
            sudo ${builder}/bin/nixos-wsl-tarball-builder \
              --extra-files "$tmp/extra" --chown /var/lib/sops-nix/key.txt 0:0 "$out"
            sudo chown "$(id -u):$(id -g)" "$out"
            echo "-> $out"
          '';
        };
    };
}
