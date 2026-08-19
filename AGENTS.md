# Repository Guidelines

[docs/References.md](docs/References.md) indexes source material; den, dendritic and the rest are vendored under `references/repos/`.
Derive den and Nix behaviour from `references/`, never from memory.
Docs are terse declarative records of goals, decisions, vocabulary, and open questions; they never narrate process, explain their own composition, justify absences, or repeat what a referenced source answers.

Hosts and their systems are declared in [modules/den.nix](modules/den.nix); [README.md](README.md) carries the build, provisioning, secrets, and skill-linking commands.
Run Nix from the Windows host with `wsl --cd "<repo>" -- <cmd>`: the NixOS instance is `phos-wsl`, and binfmt builds any host, aarch64 included.

## Vocabulary

An **entity** (`den.hosts.<sys>.<name>`, `den.homes.<sys>.<who>`) resolves by collecting the **aspect** of the same name (`den.aspects.<name>`).
Class keys (`nixos`, `homeManager`) become modules for the entity.
Aspects compose via `includes`, nest under `provides`, and take `{ host, user }` context when parametric.
**Batteries** (`den.batteries.*`) are reusable aspects shipped by den.

## Working Rules

- `flake.nix` is generated: change `flake-file.inputs.*` in the consuming module, then `nix run .#write-flake`.
- Declare an input beside its consumer; `modules/inputs.nix` is for universal ones only.
- `modules/` holds `.nix` and nothing else. import-tree auto-imports every file under it, and the option key is always `den.aspects.<name>`.
- Non-nix data gets a top-level directory per domain (`skills/`, `secrets/`, `policy.hujson`), reached via `inputs.self + "/…"` the way `ssh.nix` reads `secrets/public.toml`.
- Reach for `den.batteries.X` and `den.aspects.X` directly in `includes`.
- Write self-explanatory code with no comments; a comment means the code is not readable enough. The rare exception is a constraint the code cannot express, such as a hardware quirk or an upstream bug.
- Prefer declaring a thing over scripting it. Where an imperative step is unavoidable, document the command instead of committing a wrapper script.

## Workflow

Run `nix flake check --all-systems` and `nixfmt` on changed files.
Commit once at the end of a task (split only when clearly separable): conventional subject, no body, no co-author; don't push.
