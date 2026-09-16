# Repository Guidelines

NixOS and home-manager configs for four hosts, composed with the den aspect pattern over a dendritic flake-parts tree.
comin deploys `main` to every host, so a push is a deploy.

## Working Rules

- Great, not good: build the end state as if the config had always been designed for it, refactoring or deleting whatever stands in the way.
- Write self-explanatory code with no comments; a comment means the code is not readable enough.
  The rare exception is a constraint the code cannot express.
- Prefer declaring a thing over scripting it: a command run once belongs in the README, a repeated fetch or migration in `scripts/`.
- Get the nouns and verbs right; no abbreviations; units and qualifiers last, by descending significance.
- Docs are terse declarative records of goals, decisions, vocabulary, and open questions, each fact in exactly one place.
- Write one sentence per Markdown source line.

## Codebase

- Every `.nix` file under `modules/` is auto-imported.
- `flake.nix` is generated: edit `flake-file.inputs`, then run `nix run .#write-flake`.
- Upstream sources: `references/repos/`, populated by `scripts/clone-references.sh`.

## Workflow

Run `nix flake check --all-systems` and `nix fmt`.
From Windows, you may use `wsl --cd "<repo>" -- <cmd>`.
Commit once at the end of a task (split only when clearly separable): conventional subject, no body, no co-author; don't push.
