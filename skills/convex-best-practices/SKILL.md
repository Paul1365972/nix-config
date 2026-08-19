---
name: convex-best-practices
description: Audit Convex functions against the official best practices.
disable-model-invocation: true
argument-hint: [path or nothing for the whole project]
---

# Convex best practices audit

Audit what the argument names. With no argument, audit every Convex function in the project and present the plan before changing anything. When you have just made changes in this conversation, audit only those and fix them as you go.

[`references/best-practices.md`](references/best-practices.md) holds the rules. Read the sections that bear on the code in front of you, not the whole file.

Grep for each rule's signature: unawaited promises, `.filter` on queries, unbounded `.collect`, missing argument validators, public functions without access control, `ctx.runQuery` and `ctx.runMutation` inside queries and mutations, `Date.now()` in queries, `ctx.db` calls without a table name, redundant indexes.

A rule that looks broken often has a documented exception in the reference, so read the surrounding code before calling it a finding.

Report every finding as `file:line` with the offending code and the fix, grouped by rule. A rule you checked and found clean does not need a line in the report.
