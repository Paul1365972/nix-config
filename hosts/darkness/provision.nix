{ inputs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    let
      image = inputs.self.nixosConfigurations.darkness.config.system.build.sdImage;
    in
    {
      packages.darkness-sd-image = image;

      packages.provision-darkness = pkgs.writeShellApplication {
        name = "provision-darkness";
        runtimeInputs = with pkgs; [
          config.packages.host-key
          jq
          util-linux
          zstd
        ];
        text = ''
          out="''${1:-result-darkness.img}"
          zstd -d -f ${image}/sd-image/*.img.zst -o "$out"
          chmod 600 "$out"
          parts=$(sfdisk -J "$out" | jq -r '.partitiontable.partitions[1] | "\(.start) \(.size)"')
          off=$(( $(echo "$parts" | cut -d' ' -f1) * 512 ))
          len=$(( $(echo "$parts" | cut -d' ' -f2) * 512 ))
          loop=$(sudo losetup -f --show -o "$off" --sizelimit "$len" "$out")
          trap 'sudo umount "$loop" 2>/dev/null || true; sudo losetup -d "$loop"' EXIT
          mnt=$(mktemp -d)
          sudo mount "$loop" "$mnt"
          sudo install -d -m 0700 "$mnt/var/lib/sops-nix"
          host-key darkness | sudo install -m 0600 /dev/stdin "$mnt/var/lib/sops-nix/key.txt"
          sudo umount "$mnt"
          rmdir "$mnt"
          echo "-> $out"
        '';
      };
    };
}
