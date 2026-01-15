# Dynamic Aspects: Functions into Aspects

The second type are **functions** that return an aspect, much like a Nix `module` can be a function that returns a module.

This is where Den configurations become truly generic and reusable.

Functional aspects can be defined as let-bindings for short, one-shot usage or as part of an `<aspect>.provides` attribute set.

Here's a simplified version of our [user-shell](modules/aspects/provides/user-shell.nix) included battery:

```nix
den.aspects.utils.provides.myShell = shell: {
  nixos.programs.${shell}.enable = true;
  homeManager.programs.${shell}.enable = true;
};

den.aspects.vic.includes = [
  (den.aspects.utils._.myShell "fish")
];
```

We will continue exploring more advanced functional aspects in the next sections.