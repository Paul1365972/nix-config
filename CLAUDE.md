# CLAUDE.md

Guidance for Claude Code working in this repo.

## Project

NixOS config using the [den](https://github.com/denful/den) aspect-oriented Dendritic pattern with flake-parts and home-manager. All hosts run the `paul` user. Docs: [den.denful.dev](https://den.denful.dev).

| Host | System | Description |
|------|--------|-------------|
| `phos` | x86_64-linux | Laptop, dual boot, Hyprland |
| `phos-wsl` | x86_64-linux | WSL2 instance |
| `darkness` | aarch64-linux | Raspberry Pi kiosk (labwc + chromium) |

## Working here

- Read the relevant submodules under `docs/repos/` directly. Most useful: `denful-den-wiki`, `denful-den/templates/default/`, `denful-den/CLAUDE.md`, `mightyiam-dendritic`.
- Read modules under `modules/` directly when orienting yourself.
- `docs/imperative/darkness/` is the original imperative Pi setup, kept as historical reference.

## Running Nix from this Windows host

`wsl --cd "<repo>" -- <cmd>` runs inside the `phos-wsl` NixOS instance; the repo is shared at `/mnt/d/...`. Use this to evaluate or build any host (aarch64 included, via binfmt).

## Den model

An **entity** (`den.hosts.<sys>.<name>`, `den.homes.<sys>.<who>`) is resolved by collecting an **aspect** of the same name (`den.aspects.<name>`). An aspect's class keys (`nixos`, `homeManager`, …) become modules in those classes for the entity. Aspects compose via `includes`, organise sub-aspects under `provides`, and can take context (`{ host, user }: { … }`) when parametric.

`den.batteries.*` are reusable aspects (`define-user`, `primary-user`, `user-shell`, `hostname`, `home-manager`, …) shipped by den; `home-manager` auto-wires into every host just by importing den. `den.schema.{host,user,home}` declares typed options on entities. `den.policies` and `den.batteries.forward` enable custom classes — see `denful-den/CLAUDE.md` if needed.

## Conventions

1. **Never edit `flake.nix`** — it's generated. Change `flake-file.inputs.*` in any module, then run `nix run .#write-flake`.
2. **Place inputs next to their consumer.** Only universal inputs live in `modules/inputs.nix`.
3. **import-tree** auto-imports every `.nix` under `modules/`. Subfolders are organisational; the option key is always `den.aspects.<name>`.
4. **Use `den.batteries.X` / `den.aspects.X` directly** in `includes` lists. Angle-bracket imports are not enabled here.

## Batteries we use

`den.batteries.define-user`, `den.batteries.hostname` (both via `den.default.includes` in `defaults.nix`), `den.batteries.primary-user`, `den.batteries.user-shell` (both in `paul.nix`).

## Provisioning

Run on a host with the master sops key (phos or phos-wsl):

- `nix run .#installer` → `result-installer.iso` (live USB for phos install)
- `nix run .#darkness` → `result-darkness.img` (raw image, key injected; `dd` to SD card)
- `nix run .#phos-wsl` → `result-phos-wsl.tar.gz` (`wsl --import`)

On an already-keyed host: `nh os switch .` (matches by hostname) or `nh os switch . -H <host>`.

For first-time phos install: boot installer USB → partition/format/mount at `/mnt` → `nixos-install --flake github:Paul1365972/nix-config#phos` → seed key (from phos-wsl: `sops -d --extract '["phos-age-key"]' secrets/keys.yaml | ssh root@phos install -Dm600 /dev/stdin /mnt/var/lib/sops-nix/key.txt`) → reboot.
