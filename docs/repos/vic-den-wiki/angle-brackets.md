# Den Angle-Brackets syntax.

> Angle brackets is an experimental, opt-in feature.

When Den's `__findFile` is in scope, you can do:

```nix
   <pro/foo/bar> # and it will resolve to:
   den.aspects.pro.provides.foo.provides.bar

   <pro/foo.includes> # resolves to:
   den.aspects.pro.provides.foo.includes

   <den/import-tree/home> # resolves to:
   den.provides.import-tree.provides.home

   <den.default> # resolves to
   den.default

   # When the vix remote namespace is enabled
   <vix/foo/bar> # resolves to
   den.ful.vix.foo.provides.bar
```

You can bring `__findFile` into scope in two ways:

```nix
# on a lexical scope via a let-binding
den.aspects.my-laptop.includes = 
let
  inherit (den.lib) __findFile;
in [ <den/home-manager> ];
```

Or, globally on each module scope.

To enable it, have a module with:

```nix
{ den, ... }:
{
  _module.args.__findFile = den.lib.__findFile;
}
```

Then, bring `__findFile` into scope from module args:

```nix
{ __findFile, ... }:
  den.default.includes = [ <den/home-manager> ];
}
```
