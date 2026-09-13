# Secrets

Encrypted with [sops-nix](https://github.com/Mic92/sops-nix) and age; the `*.yaml` files are committed, private keys never are.
Recipients are declared in [`.sops.yaml`](.sops.yaml).

| File | Holds | Readable by |
|------|-------|-------------|
| `common.yaml`   | login hash, SSH identities | admin, phos, phos-wsl, darkness, saber |
| `darkness.yaml` | WiFi PSK, Tailscale auth key | admin, phos, phos-wsl, darkness |
| `saber.yaml`    | service secrets (Caddy, Synapse, Nextcloud, Traccar, Cloudflare), Tailscale auth key | admin, phos, phos-wsl, saber |
| `keys.yaml`     | every host's private age key, for provisioning | admin, phos, phos-wsl |
| `public.toml`   | public keys, read in plaintext at evaluation | everyone |

`darkness` and `saber` are left out of `keys.yaml` so a stolen Pi or server cannot read the other identities.
`admin` is offline escrow only.
Every host decrypts at activation with the key at `/var/lib/sops-nix/key.txt`; `nix run .#host-key <host>` prints that key from `keys.yaml` on an admin.

## One-time setup (on any Linux box with nix)

```bash
for id in admin phos phos-wsl darkness saber; do age-keygen -o $id.key; done
# Put each public key (age1...) into .sops.yaml; escrow admin.key offline.

export SOPS_AGE_KEY_FILE=$PWD/admin.key
sops secrets/common.yaml     # user-password: "$6$..."
sops secrets/darkness.yaml   # wifi-himmel: "HIMMEL_PSK=<psk>"  tailscale-authkey: "tskey-..."
sops secrets/saber.yaml      # service secrets, tailscale-authkey
sops secrets/keys.yaml       # <host>-age-key: file contents

# Seed the two admins (once): sudo install -Dm600 <host>.key /var/lib/sops-nix/key.txt
rm -f *.key   # keep only the escrowed admin copy
```

Afterwards `sops secrets/<file>.yaml` edits a file and `nix run .#provision-<host>` redeploys a host.
