# Statics: Including Plain Attribute Sets

There are two fundamental types of aspects that can be used in an `<aspect>.includes`. The first are **static includes**, which means you are including an anonymous aspect by using a plain attribute set.

```nix
den.default.includes = [
  { nixos.system.stateVersion = "25.11"; }
];

# instead of assigning **owned** attributes in den.default:
# den.default.nixos.system.stateVersion = "25.11";
```

Our previous example is trivial, but statics make more sense when they are part of an aspect tree and are not included in `den.default` but selectively on other aspects.

```nix
den.aspects.editors._.vim = {
  homeManager.programs.vim.enable = true;
};

den.aspects.vic.includes = [
  den.aspects.editors._.vim # a static include
];
```