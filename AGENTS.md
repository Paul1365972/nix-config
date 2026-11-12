# Repository Guidelines

comin deploys `main` to every host, so a push is a deploy.

## Working Rules

- Great, not good: build the end state as if the config had always been designed for it, refactoring or deleting whatever stands in the way.
- Prefer declarative configuration; repeated maintenance belongs in `scripts/`.
- Get the nouns and verbs right; no abbreviations; units and qualifiers last, by descending significance.
- Keep public documentation to a brief introduction and architecture links for readers borrowing parts of the setup.
- Write one sentence per Markdown source line.

## Codebase

- Every `.nix` file under `modules/` is auto-imported.
- `flake.nix` is generated: edit `flake-file.inputs`, then run `nix run .#write-flake`.
- Upstream sources: `references/repos/`, populated by `scripts/clone-references.sh`.

## Workflow

Run `nix flake check --all-systems` and `nix fmt`.
From Windows, you may use `wsl --cd "<repo>" -- <cmd>`.
Don't push.
