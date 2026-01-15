# Obtaining an OS Configuration

## The Initial `{ OS, host }` Context

Suppose you have a single `hostAspect` and a single `userAspect`. An OS-level configuration -one whose `class` is `nixos` or `darwin`- starts by applying the hostAspect to `{ OS, host }` (the initial, or _intent_ context). Here, `host` is the `den.hosts.<system>.<host>` value, and `OS` is a self-reference to the aspect that is being applied.

The `hostAspect` must then return the whole OS configuration. This is done, by including the results of calling other aspects with a context, this is the job of Den's [`dependency`](modules/aspects/dependencies.nix) system.

### Steps that happen to collect the complete `OS` configuration.

Given that `hostAspect` is a `parametric` aspect, the functor applies functions from `hostAspect.includes` that support at least `{ OS, host }` context.

Since `den.default` is included in this list, and it has an `(exactly { OS, host }: osDependencies)` dependency, the function `osDependencies` is used to return the whole OS configuration by doing the following:

- First, [**owned**](aspects.html#owned-nix-configuration-modules)-modules and [**static**](statics.html)-includes are obtained from the `den.default` aspect.

- Similarly, we obtain _owned_-configurations and _static_-includes from the `hostAspect` itself.

If the Host has Users, for each user we include the following dependencies:

- The _owned_-configurations and _static_-includes from the `userAspect`, because it can provide static values for OS-`class`.

- The result of applying `userAspect` with a now expanded `{ OS, host, user }` context. This is where a user can provide [**parametric**](context-aware.html) configuration for the OS.

The aggregated OS-`class` modules of all these transitive aspects is the resulting configuration for the host.


