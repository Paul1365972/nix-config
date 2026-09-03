# Repository Guidelines

NixOS and home-manager configs for four hosts, composed with the den aspect pattern over a dendritic flake-parts tree.
Every file under `modules/` is auto-imported, declares one `den.aspects.<name>`, and reaches a host through [modules/den.nix](modules/den.nix); comin deploys `main` to every host, so a push is a deploy.

## Working Rules

- Great, not good: build the end state as if the config had always been designed for it, refactoring or deleting whatever stands in the way.
- Write self-explanatory code with no comments; a comment means the code is not readable enough. The rare exception is a constraint the code cannot express.
- Prefer declaring a thing over scripting it: a command run once belongs in the README, a repeated fetch or migration in `scripts/`.
- Get the nouns and verbs right; no abbreviations; units and qualifiers last, by descending significance.
- Docs are terse declarative records of goals, decisions, vocabulary, and open questions, each fact in exactly one place.

## Codebase

- An **entity** (`den.hosts.<sys>.<name>`, `den.homes.<sys>.<who>`) collects the **aspect** of the same name, whose class keys (`nixos`, `homeManager`) become its modules; aspects compose via `includes`, nest under `provides`, and take `{ host, user }` context when parametric. **Batteries** (`den.batteries.*`) ship with den.
- `flake.nix` is generated: change `flake-file.inputs.*` beside the consumer, then `nix run .#write-flake`.
- An aspect's assets sit beside it; data spanning aspects gets a top-level directory (`skills/`, `secrets/`, `scripts/`, `policy.hujson`), reached via `inputs.self + "/…"`.
- `references/repos/` is gitignored, filled by `scripts/clone-references.sh`, and is where den and Nix behaviour comes from, never memory; [docs/References.md](docs/References.md) indexes the rest.
- `saber` is the only public host: Caddy terminates its vhosts, admin UIs are tailnet-only Tailscale Services granted in `policy.hujson`.
- [README.md](README.md) has the build, provisioning, secrets, and skill commands. Run Nix from Windows with `wsl --cd "<repo>" -- <cmd>`; binfmt on `phos-wsl` builds any host.

## Workflow

Run `nix flake check --all-systems` and `nixfmt` on changed files.
Commit once at the end of a task (split only when clearly separable): conventional subject, no body, no co-author; don't push.
