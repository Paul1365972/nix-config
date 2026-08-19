---
name: type-audit
description: Audit TypeScript for unsound types and hacky as casts.
disable-model-invocation: true
argument-hint: [path or nothing for the whole project]
---

# Type audit

Audit what the argument names. With no argument, audit the whole project and present the plan before changing anything. When you have just made changes in this conversation, audit only those and fix them as you go.

Grep for `any`, `unknown`, ` as `, `!.`, `??`, `?.`, then judge each hit against the categories below. Report every finding as `file:line` with the offending code and the fix, grouped by category. A false positive costs more than a missed nit.

## Unwarranted `any`

Replaceable with a real type. Genuinely unavoidable ones stay, such as a third-party constraint with no typed alternative.

## Misused `unknown`

The type is actually known or narrows trivially. A value cast immediately after being typed `unknown` should have been typed properly.

## `as` casts

The category that matters most. Each cast is one of three things:

- **Lying.** The runtime value does not match the asserted type.
- **Papering over.** Restructuring or a type guard would be correct.
- **Legitimate.** `as const`, framework callback context, narrowing from a validated source.

Flag the first two.

## Cursed inference

- Missing return annotations that cause inference chains or circular references
- Generics resolving to something unreadable where an annotation would do
- Inferred types far broader than reality, `string | number | boolean` where only `string` is possible
- Types pulled from library internals, `Parameters<typeof x>[0]`

## `undefined` and `null`

- The two used inconsistently for one meaning
- `?` on fields that are always present, or missing from fields that are not
- `!` where a check or refactor would be safer
- `??` and `?.` masking a bug rather than handling a real case
