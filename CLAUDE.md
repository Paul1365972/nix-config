# CLAUDE.md

NixOS config using the [den](https://github.com/denful/den) aspect-oriented Dendritic pattern (flake-parts + home-manager).
All hosts run the `paul` user.
Docs: [den.denful.dev](https://den.denful.dev).

| Host | System | Description |
|------|--------|-------------|
| `phos` | x86_64-linux | Laptop, dual boot, Hyprland |
| `phos-wsl` | x86_64-linux | WSL2 instance |
| `darkness` | aarch64-linux | Raspberry Pi 5 kiosk (labwc + chromium) |
| `saber` | x86_64-linux | Home lab server |

## Working here

- Read `modules/` directly to orient. Reference under `docs/repos/`: `denful-den-wiki`, `denful-den/CLAUDE.md`, `mightyiam-dendritic`.
- Run Nix from this Windows host via `wsl --cd "<repo>" -- <cmd>` (NixOS instance `phos-wsl`; repo at `/mnt/d/...`; builds any host incl. aarch64 via binfmt).

## Den model

An **entity** (`den.hosts.<sys>.<name>`, `den.homes.<sys>.<who>`) resolves by collecting the **aspect** of the same name (`den.aspects.<name>`).
Class keys (`nixos`, `homeManager`) become modules for the entity.
Aspects compose via `includes`, nest under `provides`, and take `{ host, user }` context when parametric.
`den.batteries.*` are reusable aspects shipped by den.

## Conventions

1. **Never edit `flake.nix`** — it's generated. Change `flake-file.inputs.*` in a module, then `nix run .#write-flake`.
2. Place inputs next to their consumer; only universal ones in `modules/inputs.nix`.
3. import-tree auto-imports every `.nix` under `modules/`; the option key is always `den.aspects.<name>`.
4. Use `den.batteries.X` / `den.aspects.X` directly in `includes`.

## Provisioning

Plain images: `nix build .#installer-iso` · `nix build .#darkness-sd-image`.

`provision-*` wrappers bake in the host's sops key (read from `/var/lib/sops-nix/key.txt` via `sudo`; run on a keyed host — phos/phos-wsl):

- `nix run .#provision-darkness [out]` → `result-darkness.img` (`dd` to SD)
- `nix run .#provision-phos-wsl [out]` → `result-phos-wsl.tar.gz` (`wsl --import`)
- `nix run .#provision-saber -- root@saber [args…]` → deploy via nixos-anywhere

On a keyed host: `nh os switch . [-H <host>]`.
