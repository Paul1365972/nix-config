# NixOS Configuration

NixOS configs using the [den](https://github.com/denful/den) aspect pattern.

## Hosts

- **phos** — Laptop
- **phos-wsl** — WSL
- **darkness** — Raspberry Pi 5 kiosk
- **saber** — home lab server

## Usage

```bash
nh os switch .                  # build + activate + set boot default (-H <host> to target)
nh os boot .                    # apply on next reboot
nh os rollback                  # revert to previous generation
nix run .#write-flake           # regenerate flake.nix after editing flake-file.inputs
nix flake check --all-systems   # evaluate every host
sops secrets/<file>.yaml        # edit an encrypted secret
```

## Provisioning

Plain images: `nix build .#installer-iso`, `nix build .#darkness-sd-image`.

`provision-*` wrappers bake in the host's sops key (run on a keyed admin — phos/phos-wsl; needs `sudo`):

```bash
nix run .#provision-darkness    # -> result-darkness.img ; dd to SD card
nix run .#provision-phos-wsl    # -> result-phos-wsl.tar.gz ; wsl --import
nix run .#provision-saber -- root@saber   # deploy via nixos-anywhere
```

## Secrets

Encrypted with [sops-nix](https://github.com/Mic92/sops-nix) and committed.
`phos`/`phos-wsl` are admins that can (re)deploy any host.
Setup: [`secrets/README.md`](secrets/README.md).
