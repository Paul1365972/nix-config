# Repository Guidelines

comin deploys `main` to every host, so a push is a deploy.

## Working Rules

- Great, not good: build the end state as if the config had always been designed for it, refactoring or deleting whatever stands in the way.
- Write self-explanatory code with no comments; a comment means the code is not readable enough. Exceptions are a constraint the code cannot express or comments that follow our current coding style.
- Get the nouns and verbs right; no abbreviations; units and qualifiers last, by descending significance.
- Keep public documentation to a brief introduction and architecture links for readers borrowing parts of the setup.
- Write one sentence per Markdown source line.

## Codebase

- Every `.nix` file under `modules/` is auto-imported.
- `flake.nix` is generated: edit `flake-file.inputs`, then run `nix run .#write-flake`.
- The instructions and skills every agent loads live in `modules/users/paul/` (`AGENTS.md` and `skills/`), linked into each agent by `scripts/link-agents.ps1`.

## Checks

Run `nix fmt` and `nix flake check --all-systems` in WSL: `wsl --cd "<repo>" -- <cmd>`.
Nix sees only files Git tracks, so stage new files first.
Nix cannot read a worktree that Windows Git created; run the checks in the main checkout.
