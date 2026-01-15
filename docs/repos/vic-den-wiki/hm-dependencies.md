# Standalone HomeManager Configuration Dependencies

Similar to previous cases, obtaining an stand-alone HomeManager configuration happens like this:

## The `{ HM, home }` _Intent_ Context

The `homeAspect` is applied to the context `{ HM, home }`, the dependency system takes the following steps:

- Obtains _owned_-configurations and _static_-includes from `den.default`.

- Obtains _owned_-configurations and _static_-includes from `homeAspect`.

The `homeManager` class of these transitive aspects is the resulting configuration.
