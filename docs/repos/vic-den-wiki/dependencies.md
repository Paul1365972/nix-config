# Dependency System

Den implements its [dependency](modules/aspects/dependencies.nix) system between Hosts, Users, and Homes by using _contexts_.

An aspect is basically a function that returns a set of configurations. The argument to this function is what Den calls a **context**; specifically, the argument's attribute names and the required arguments a [function can take](nix/fn-can-take.nix) is what decides if a function is invoked or not.

It is the job of Den's `takes.atLeast`, `takes.exactly`, and `funk` [combinator](nix/lib.nix) to select and apply the context only to functions from `<aspect>.includes` that support the context.

Read the following sections to learn about the different context variants that Den uses by default.

## How This Relates to `den.default.includes` or any `parametric.atLeast` functor.

Remember that `den.default` is just an aspect with functor `parametric.atLeast`.

In particular, `den.default` is the backbone of dependency resolution in Den, since all Hosts, Users, Homes include `den.default`. Dependency resolving functions are registered in `den.default.includes`, and you can provide your own. Just take the following in mind:

If you add a function like this to any `parametric.atLeast` aspect:

```nix
den.default.__functor = den.lib.parametric.atLeast;
den.default.includes = [
  ({ host, ... }: { nixos.x = 1; })
];
```

The function will be invoked whenever a the aspect is applied to an argument that has at least the `host` attribute. This could happen for several different contexts, like `{ OS, host }` initially, and later `{ OS, host, user }` for each host user, or others like `{ HM, host, user}`, or even your own custom contexts.

If the context is too loose and applies multiple times, it is possible that the resulting value of the function will produce duplicate configuration values. This is more evident on `listOf _`-type configuration options, where your function will generate duplicated values for each time the function was called.

To prevent this, you need to make the function argument-names more explicit by requesting a more attributes from the context or by using `den.lib.takes.exactly` if using an smaller context:

```nix
den.default.includes = [
  (den.lib.takes.exactly ({ OS, host }: { nixos.x = 1; }))
];
```

This will only apply to `{ OS, host }` and not to `{ OS, host, user }`. Avoiding duplication for each of the host's users.

## With Great Power Comes Great Responsibility

Given the flexibility of `den.default`, it is recommended to use precise contexts or install parametric aspects specifically at particular host, user, or home aspects instead of abusing `den.default`.

As an example of creating your own routers, see the default-template's [routes.nix](templates/default/modules/aspects/eg/routes.nix)

## Creating Your Own Intent Context

A context is nothing more than a set of arguments. You can create your own that dispatches and includes differently than our built-in `OS` and `HM` contexts.