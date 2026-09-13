---
name: no-effect
description: Find React effects that should not exist and remove them. Use only when explicitly invoked.
disable-model-invocation: true
argument-hint: [path or nothing for the whole project]
---

# You might not need an effect

Audit what the argument names. With no argument, audit every component in the project and present the plan before changing anything. When you have just made changes in this conversation, audit only those and fix them as you go.

Grep for `useEffect`, then ask of each one why the code runs:

- The component was displayed, so the effect stays.
- The user did something, so it belongs in an event handler.
- Props or state changed and the new value has to reach the screen, so calculate it during render.

An effect that synchronizes with something outside React, a subscription, a browser API, or a request with cleanup, is correct as it is.

[`references/you-might-not-need-an-effect.md`](references/you-might-not-need-an-effect.md) has the rewrite for each anti-pattern. The ones that show up are state derived from props, expensive work that wants `useMemo`, resetting state that wants a `key`, chained effects that each trigger the next, and fetch effects missing cleanup.

Report every finding as `file:line` with the anti-pattern it matches and the replacement.
