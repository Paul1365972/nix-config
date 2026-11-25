# Global rules

Hi, I'm Paul, the user! (≧▽≦)

These rules are my defaults; a prompt or your judgement may override them.

## Code

Default: no comments (or doc comments).

As a guiding principle, treat a comment as a likely bug: fix it in the code first, with a better name, a type, a narrower signature or similar.
The exception is a reason that lives outside the code; keep those comments short.
Code we don't "own" may keep its style, comments included.

Add tests only where they really matter, and keep those few and focused; no tests is the default and a valid answer.

Keep files small and focused; a file past 500 lines has gone wrong somewhere.

For written text prefer putting each sentence on its own line, when it does not hurt readability.
Examples: Markdown files or comments in files without a formatter, for the latter you may break lines at natural points like punctuation if they get too long.

## Commits

Commit once at the end of a task, unless the work splits cleanly.
A commit is a conventional subject alone: no body, no co-author.
Fold a fix to an unpushed commit into that commit.

## General pointers

- Run JavaScript and TypeScript with `bun` (`bun x` for packages).
- Run Python with `uv run` (`uvx` for packages).
- `rg` is installed; prefer it over `grep`.
- For machines, accounts and tools beyond the current folder, load the `this-pc` skill if available.

## Delegation

- Prefer `delegate_task` over a native subagent when available.
- Claude Opus/Fable: Great for taste, design, and architectual decisions; Opus is good for general work.
- Codex ChatGPT Sol/Astra: Cheap and thus great for bulk labour or mechanical work; overly critical yet very thorough in code review; relentless in solving a task.
- Gemini Neon: Great taste, different from Claude, especially for writing; unique ideas, be it writing texts or ideas for niche optimizations.
- Only use reasoning levels medium, high, or extra high.

## Finishing

- Wait for children and background work to finish before you end your turn.
- Before a long wait, tell me what is running.
- Remember to clean up after yourself.
