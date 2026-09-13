# nix-config

NixOS and home-manager configs for four hosts, composed with the [den](https://github.com/denful/den) aspect pattern.

## Hosts

| Host | Role |
|------|------|
| `phos` | Laptop. Windows today, NixOS dual boot next; `nix run .#vm` boots the config in QEMU meanwhile. |
| `phos-wsl` | NixOS on WSL, the build and admin box. |
| `darkness` | Raspberry Pi 5 kiosk. |
| `saber` | Home lab server, the only public host. |

## Layout

| Directory | Holds |
|-----------|-------|
| `modules/flake/` | How the flake is assembled: inputs, formatter. Nothing den. |
| `modules/hosts/<name>/` | The host entity and aspect: includes, hardware, disks, services, provisioning, assets |
| `modules/users/<name>/` | The user aspect: packages, SSH identities, agent skills |
| `modules/features/` | Aspects shared across hosts and users |
| `secrets/` | sops files and their recipients |
| `tailnet/` | Tailscale policy, applied by CI |
| `scripts/` | Repeated fetches |
| `docs/` | Link index |

## Commands

```bash
nh os switch .                  # build, activate, set boot default (-H <host> to target)
nh os boot .                    # apply on next reboot
nh os rollback                  # revert to the previous generation
nix flake check --all-systems   # evaluate every host, lint, verify formatting
nix fmt                         # nixfmt, deadnix, statix
nix flake update <input>        # bump one input; den changes its API between releases, so bump it alone
nix run .#write-flake           # regenerate flake.nix after editing flake-file.inputs
sops secrets/<file>.yaml        # edit an encrypted secret
```

## Deploying

comin polls `main` on every host, so a merge is a deploy.
CI evaluates everything and builds all four host closures; merge when it is green.
To try a change on one host first, push it to `testing-<host>`: comin activates it without touching the bootloader, and a reboot or the next push to `main` undoes it.
saber and darkness also run OpenSSH on the LAN as the way in when tailscaled is down.

## Provisioning

`provision-*` wrappers bake the host's sops key into the artifact; run them on a keyed admin (phos-wsl) with `sudo`:

```bash
nix run .#provision-darkness              # -> result-darkness.img, dd it to the SD card
nix run .#provision-phos-wsl              # -> result-phos-wsl.tar.gz, wsl --import it
nix run .#provision-saber -- root@saber   # install over SSH with nixos-anywhere
nix build .#darkness-sd-image             # plain image without a key
nix build .#installer-iso                 # x86 live installer, for phos
```

The `images` CI job builds the plain image and the installer on manual dispatch.

phos: [`modules/hosts/phos/disko.nix`](modules/hosts/phos/disko.nix) is the layout for the full install (LUKS, btrfs, swapfile).
Dual boot needs a hand-made partition instead of disko; keep the same subvolumes so the config stays identical.

## Agent skills

Skills live in [`modules/users/paul/skills/`](modules/users/paul/skills/), one directory per skill, and reach Claude Code and Codex on NixOS hosts through home-manager.
Windows cannot run Nix; link them once:

```powershell
Get-ChildItem D:\Programming\Projects\nix-config\modules\users\paul\skills -Directory | ForEach-Object {
  foreach ($agent in ".claude", ".codex") {
    New-Item -ItemType Junction -Force -Path "$HOME\$agent\skills\$($_.Name)" -Target $_.FullName
  }
}
```

Vendored skills record their origin in `metadata.source`; the frontmatter is local and reverses the invocation settings.
`scripts/update-skills.sh` diffs every vendored body against its upstream.

## Secrets

sops-nix with one age key per host, committed encrypted. Setup and recipients: [`secrets/README.md`](secrets/README.md).

## Backups

saber copies its service state to the data HDD nightly with borg ([`modules/hosts/saber/backup.nix`](modules/hosts/saber/backup.nix)).
That covers an SSD failure or a bad upgrade, not a dead HDD.
