# OS HomeManaged Configuration Dependencies

When [home-manager integration](modules/aspects/provides/home-manager.nix) has been enabled on a Host, the following happens to resolve the complete `homeManager` class configuration for a User.

## The `{ HM, user }` _Intent_ Context

The [home-manager.nix](modules/aspects/provides/home-manager.nix) integration starts by applying the `userAspect` to the initial context `{ HM, user, host }`.

Similarly to what happened for the OS, the [`dependency`](modules/aspects/dependencies.nix) system does the following steps:

- Obtains _owned_-configurations and _static_-includes from `den.default`.

- Obtains _owned_-configurations and _static_-includes from `userAspect`.

- Obtains the result of applying `hostAspect` to the context `{ OS, HM, user, host }`. This is the oportunity of a Host aspect to provide **parametric** `homeManager`-class configuration to its users.

The `homeManager` modules from these transitive dependencies conform the User's home-manager module.