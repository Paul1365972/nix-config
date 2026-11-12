---
name: no-op
description: Cut lines from a skill or AGENTS.md that change nothing or restrict needlessly. Use only when explicitly invoked.
disable-model-invocation: true
argument-hint: [path]
---

Delete every line the model would follow without being told, and every line that would be wrong for some task the document covers.
What stays is what the model cannot know: a choice between equals, a name, a fact about this setup.

Lines that stayed:

- Run Python with `uv run` (`uvx` for packages).
- Commit once at the end of a task unless the work splits cleanly: conventional subject, no body, no co-author.
- Consult the latest Codex Sol and Astra and the latest Claude Fable and Opus.
- Codex tends to overstate problems.

Lines that went:

- Keep answers brief and plain.
- Write one brief and give it unchanged to every member: the question, the material, the user's priorities, and the form of the answer.
- Report three lists: what you will do, what the user has to decide, and what is not worth doing.
- When a task ends, remove what you created for it: temp files, worktrees, branches, servers, browser tabs.
