# Repository Guidelines

NixOS and home-manager configs for four hosts, composed with the den aspect pattern over a dendritic flake-parts tree.
comin deploys `main` to every host, so a push is a deploy.

## Working Rules

- Great, not good: build the end state as if the config had always been designed for it, refactoring or deleting whatever stands in the way.
- Write self-explanatory code with no comments; a comment means the code is not readable enough. The rare exception is a constraint the code cannot express.
- Prefer declaring a thing over scripting it: a command run once belongs in the README, a repeated fetch or migration in `scripts/`.
- Get the nouns and verbs right; no abbreviations; units and qualifiers last, by descending significance.
- Docs are terse declarative records of goals, decisions, vocabulary, and open questions, each fact in exactly one place.

## Codebase

- A den **entity** (`den.hosts.<system>.<name>`, declared beside its aspect in `modules/hosts/<name>/`) collects the **aspect** of the same name. `includes` composes aspects and `provides` nests them. Users opt into host `homeManager` configuration with `den.batteries.host-aspects`; account settings use the `user` class, and username strings use the `{ user }` context. User `provides.<host>` holds personal choices for that host.
- Files can contribute to the same aspect: the Hyprland desktop is one selectable aspect across several files. Mandatory host configuration attaches directly to its host aspect; selectable services own their routes, database declarations, firewall ports, backup contributions, and dashboard entries.
- Every `.nix` file under `modules/` is auto-imported and declares one thing: `flake/` is flake-parts wiring only, `hosts/` and `users/` hold entities with their aspects, `features/` the aspects they share. Assets sit beside their aspect; data spanning aspects gets a top-level directory reached via `inputs.self + "/…"`.
- `flake.nix` is generated: declare each `flake-file.inputs.<name>` beside its consumer (`modules/flake/inputs.nix` when shared), then `nix run .#write-flake`.
- Look den and Nix behaviour up in `references/repos/` (gitignored, filled by `scripts/clone-references.sh`); [docs/References.md](docs/References.md) indexes the rest.
- `saber` is the only public host: Caddy terminates its vhosts; admin UIs are tailnet-only Tailscale Services granted in `tailnet/policy.hujson`.
- Nix runs from Windows through `wsl --cd "<repo>" -- <cmd>`; binfmt on `phos-wsl` builds any host. [README.md](README.md) has the build, deploy, provisioning, secrets, and skill commands.

## Workflow

Run `nix flake check --all-systems` and `nix fmt`.
Commit once at the end of a task (split only when clearly separable): conventional subject, no body, no co-author; don't push.
