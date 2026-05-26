# NixOS Configuration

NixOS configs using the [den](https://github.com/denful/den) aspect pattern.

## Hosts

- **phos** - NixOS laptop with Hyprland
- **phos-wsl** - NixOS on WSL2
- **darkness** - Raspberry Pi 5 kiosk

## Usage

```bash
nh os switch .                  # build + activate + set boot default
nh os boot .                    # build + set boot default (apply next reboot)
nh os test .                    # build + activate, do NOT touch boot default
nh os switch -n .               # dry run (print actions only)
nh os switch -u .               # update all flake inputs, then switch
nh os rollback                  # revert to previous generation
nh os info                      # list generations
nh search <pkg>                 # search nixpkgs
nh clean all                    # GC all profiles   (nh clean user = just yours)
```

```bash
nix run .#write-flake           # regenerate flake.nix after changing modules/inputs.nix
nix flake check --all-systems   # evaluate every host
nix build .#darkness-sd-image   # cold RPi image
nix build .#phos-wsl-tarball    # WSL tarball builder
sops secrets/<file>.yaml        # edit an encrypted secret
```

## Install

```bash
# phos (laptop): get the key from an admin, then install
./scripts/provision.sh phos                # on phos-wsl -> result-phos-age-key.txt
SOPS_KEY_FILE=result-phos-age-key.txt ./scripts/install.sh phos
./scripts/install.sh                       # already-seeded host: no key needed

# phos-wsl
./scripts/provision.sh phos-wsl            # on phos -> result-phos-wsl.tar.gz
wsl --import NixOS <dir> result-phos-wsl.tar.gz --version 2

# darkness (Pi)
./scripts/provision.sh darkness            # -> result-darkness.img
sudo dd if=result-darkness.img of=/dev/sdX bs=4M conv=fsync status=progress
```

`install.sh` sets the new generation as default; reboot to activate.

## Secrets

Encrypted with [sops-nix](https://github.com/Mic92/sops-nix) and committed.
`phos`/`phos-wsl` are admins that can (re)deploy any host; `darkness` is runtime-only.
`scripts/provision.sh <target>` (run on an admin) builds the artifact with its key baked in.
Setup: [`secrets/README.md`](secrets/README.md).

## Docs

`docs/repos/` reference · `docs/dendritic-template/` template · `docs/attempt1/`, `docs/attempt2/`, `docs/imperative/` history
