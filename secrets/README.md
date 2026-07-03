# Secrets

Encrypted with [sops-nix](https://github.com/Mic92/sops-nix) + age.
The `*.yaml` files here are committed (encrypted); private keys never are.

| File | Holds | Readable by |
|------|-------|-------------|
| `common.yaml`   | login hash | admin, phos, phos-wsl, darkness, saber |
| `darkness.yaml` | WiFi PSK, Tailscale auth key | admin, phos, phos-wsl, darkness |
| `saber.yaml`    | service secrets (Caddy, Authentik, Synapse, …), Tailscale auth key | admin, phos, phos-wsl, saber |
| `keys.yaml`     | every host's private age key (for provisioning) | admin, phos, phos-wsl |

`darkness` and `saber` are left out of `keys.yaml` so a stolen Pi or server can't read the other identities.
`admin` is offline-only escrow.
Every host reads its key from `/var/lib/sops-nix/key.txt`.

## One-time setup (on any Linux box with nix)

```bash
for id in admin phos phos-wsl darkness saber; do age-keygen -o $id.key; done
# Put each public key (age1...) into ../.sops.yaml; escrow admin.key offline.

export SOPS_AGE_KEY_FILE=$PWD/admin.key
sops secrets/common.yaml     # user-password: "$6$..."
sops secrets/darkness.yaml   # wifi-himmel: "HIMMEL_PSK=<psk>"  tailscale-authkey: "tskey-..."
sops secrets/saber.yaml      # service secrets, tailscale-authkey
sops secrets/keys.yaml       # <host>-age-key: file contents

# Seed the two admins (once): sudo install -Dm600 <host>.key /var/lib/sops-nix/key.txt
rm -f *.key   # keep only the escrowed admin copy
```

Afterwards: `sops secrets/<file>.yaml` to edit, `nix run .#provision-<host>` to (re)deploy (see top-level README).
The flake won't evaluate until the files above exist and a key is at `/var/lib/sops-nix/key.txt`.
