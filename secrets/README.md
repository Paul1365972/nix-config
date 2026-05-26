# Secrets

Encrypted with [sops-nix](https://github.com/Mic92/sops-nix) + age.
The `*.yaml` files here are committed (encrypted); private keys never are.

| File | Holds | Readable by |
|------|-------|-------------|
| `common.yaml`   | login hash | admin, phos, phos-wsl, darkness |
| `darkness.yaml` | WiFi PSK, Tailscale auth key | admin, phos, phos-wsl, darkness |
| `keys.yaml`     | the phos / phos-wsl / darkness private keys | admin, phos, phos-wsl |

`darkness` is left out of `keys.yaml` so a stolen Pi can't read the other identities.
`admin` is offline-only escrow.
Every host reads its key from `/var/lib/sops-nix/key.txt`.

## One-time setup (on any Linux box with nix)

```bash
for id in admin phos phos-wsl darkness; do age-keygen -o $id.key; done
# Put each public key (age1...) into ../.sops.yaml; escrow admin.key offline.

export SOPS_AGE_KEY_FILE=$PWD/admin.key
sops secrets/common.yaml     # user-password: "$6$..."
sops secrets/darkness.yaml   # wifi-himmel: "HIMMEL_PSK=<psk>"  tailscale-authkey: "tskey-..."
sops secrets/keys.yaml       # phos-age-key / phos-wsl-age-key / darkness-age-key: file contents

# Seed the two admins (once):
#   phos-wsl:  sudo install -Dm600 phos-wsl.key /var/lib/sops-nix/key.txt
#   phos:      scripts/install.sh places it (SOPS_KEY_FILE=phos.key)
rm -f *.key   # keep only the escrowed admin copy
```

Afterwards: `sops secrets/<file>.yaml` to edit, `scripts/provision.sh <target>` to (re)deploy.
The flake won't evaluate until the files above exist and a key is at `/var/lib/sops-nix/key.txt`.
