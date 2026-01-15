# The `__functor` Pattern

In Nix, any attribute set with a `__functor` attribute can be applied as if it were a function with internal state.

```nix
let 
  dup = {
    by = 2;
    __functor = self: num: self.by * num;
  };
in dup 3 # => 6
```

## Using `<aspect>.__functor` as a Context-Aware Router

All aspects in `flake-aspects` have a default `__functor` attribute that looks like this:

```nix
{
  nixos = { a = 1; };
  __functor = aspect: context: aspect; # ignores context
}
```

The default `__functor` ignores its given argument and always returns the aspect being applied.

This means you can provide another `__functor` that, instead of ignoring `context`, inspects it along with its own internal state and, as a result, returns a different aspect that will ultimately provide the settings.

```nix
{
  nixos.foo = 24;
  __functor = aspect: context:
    if context.venus_in_aquarius then aspect
    else { includes = [ den.aspects.other-stuff ] };
}
```