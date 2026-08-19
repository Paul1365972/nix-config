# Skills

Skills for Claude Code and Codex, one directory per skill.
Linux hosts link them on rebuild via `modules/aspects/apps/agents.nix`.

Nix does not run on Windows, so link them there once.

Skills taken from upstream record their origin in `metadata.source`.
Re-fetch that URL and diff before overwriting: upstream frontmatter reverses the invocation settings.
