# Aspect-Oriented Configurations

Den [creates an aspect](modules/aspects/definition.nix) for each Host, User, and Home you define. The aspect can be accessed via its name, `den.aspects.<name>`.

For our previous example, the user `vic` has an aspect `den.aspects.vic`. If desired, multiple hosts, users, or homes can share the same aspect name. For example, you can have the same `vic` aspect in a NixOS Home-managed instance and as a standalone Home-Manager instance on Darwin.

Any file inside `modules/` can contribute to any aspect. Because of this, we say that in a Dendritic setup, features are [**incremental**](https://vic.github.io/dendrix/Dendritic.html#incremental-features).

## Aspect Structure

Aspects are provided by the [`flake-aspects`](https://github.com/vic/flake-aspects) library, so you may want to read its documentation to learn more. We will also provide more information about how Den leverages `flake-aspects` features in later sections.

For now, it is enough to mention that aspects have three fundamental kinds of attributes.

### Owned Nix Configuration Modules

_Owned_ modules are those assigned directly to an aspect, each under the name of a different Nix configuration **class**.

```nix
den.aspects.my-laptop = {
  nixos = { pkgs, ... }: {
    # Anything that is possible in any NixOS module.
    environment.systemPackages = [ pkgs.hello ];
  };
  darwin = { 
    # same for nix-darwin options.
  };
  nixvim = { };
  # or any other possible nix class.
};
```

### Provides

The `provides` attribute allows aspects to form a nested tree structure. This is the recommended way to organize your related aspects. You decide how to organize them.

`flake-aspects` defines `_` as an alias for `provides`, and you will likely find many examples using `._.` faces.

```nix
den.aspects.gaming = {
  description = "Games";
  nixos = { };
  provides = {
    emulation = {
      description = "Old is still good";
      nixos = { };
    };
  };
};
```

### Includes

The `includes` attribute is how `flake-aspects` lets you define a dependency graph between aspects.

```nix
den.aspects.vic = {
  homeManager = { };
  includes = [ den.aspects.gaming._.emulation ];
};
```

When the `vic.homeManager` module is retrieved, all `homeManager` modules from its transitive dependencies (`includes`) will also be imported into a single module.