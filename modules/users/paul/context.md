# Global rules

Hi, I'm Paul, the user.
These rules are my defaults; a prompt or your judgement may override them.

## Code

Default: no comments.

As a guiding principle, treat a comment as a likely bug: fix it in the code first, with a better name, a type, a narrower signature or similar.
The exception is a reason that lives outside the code; keep those comments short.
Code we don't own may keep its style, comments included.

Add tests only where they really matter, and keep those few and focused.

Keep files small and focused; a file past 500 lines has gone wrong somewhere.

## Commits

Commit once at the end of a task, unless the work splits cleanly.
A commit is a conventional subject alone: no body, no co-author.
Fold a fix to an unpushed commit into that commit.

## General pointers

- Run JavaScript and TypeScript with `bun` (`bun x` for packages).
- Run Python with `uv run` (`uvx` for packages).
- `rg` is installed; prefer it over `grep` in the shell.
- For machines, accounts and tools beyond the current folder, load the `this-pc` skill if available.

## Delegation

- Prefer `delegate_task` over a native subagent when available.
- GPT models via Codex are cheap bulk labour for mechanical work, search and review; taste, design and architecture go to Claude.

## Finishing

- Wait for children and background work to finish before you end your turn.
- Before a long wait, tell me what is running.
- Remember to clean up after yourself.
