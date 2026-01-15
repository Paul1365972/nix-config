# Context-Aware Functional Aspects

Functors are how Den achieves context adaptation and configuration parameterization.

Be sure to read the section about [Functors](functor.html).

> A **Parametric** aspect is one that implictly takes a _context_ parameter and *forwards* it to any _function_ registered at `.includes`.

You create a parametric aspect by using one of the `den.lib.parametric` functors detailed below.

The most common and frequenly used is the `den.lib.parametric` function itself, it expects an non-functional aspect as an **attribute-set** and creates a parametric aspect from it.

```nix
den.aspects.foo = den.lib.parametric {
  nixos.foo = 1;
  includes = [ den.aspects.bar ];
};
```

The `foo` aspect will be able to take any type of context (argument), for example it can be applied with `foo { x = 1; }` and `foo` will **forward** the same context `{ x }` to `bar` or any other of its `.includes` as long as they can take `atLeast` the same argument names.


## The `parametric.exactly` Functor

For example:

```nix
let
  a = { x, ... }: { nixos.foo = x; };
  b = { x, y }: { nixos.foo = y; };
  c = { z }: { nixos.foo = z; };

  F = parametric.exactly {
    includes = [ a b c ];
  };
in F
```

When the `F` aspect is applied like `F { x = 0; y = 1; }`, it will only invoke the `b` function, since it is the ONLY function that takes exactly the named arguments `{ x, y }`, no more, no less.

> IMPORTANT: `parametric.exactly` **only** dispatches to `.includes` functions. It will not take care of _owned_ configurations. See `parametric.withOwn`.


## The `parametric.atLeast` Functor


Using the same example as before:

```nix
let
  a = { x, ... }: { nixos.foo = x; };
  b = { x, y }: { nixos.foo = y; };
  c = { z }: { nixos.foo = z; };

  F = parametric.atLeast {
    includes = [ a b c ];
  };
in F
```

Calling `F { x = 1; y = 2; }` will invoke `a` and `b`, including both of their results. In this example, this causes different values of `nixos.foo` to be set.

> IMPORTANT: `parametric.atLeast` **only** dispatches to `.includes` functions. It will not take care of _owned_ configurations. See `parametric.withOwn`.

## The Definition of `den.default`

The [complete definition](modules/aspects/defaults.nix) of `den.default` is as follows:

```nix
den.default = den.lib.parametric.atLeast { };
```

This means that `den.default` aspect is nothing more than a dispatcher that will include the results from forwarding its given context to all `.includes` functions.

## The `parametric.withOwn` combinator.

The `parametric` function itself is an alias for `parametric.withOwn parametric.atLeast`.

Both `parametric.atLeast` and `parametric.exactly` **only** dispatch to functions. However, the `parametric.withOwn` combinator allows a parametric aspect to **also** include its [_owned_](aspects.html) configurations and [_static_](statics.html) includes.

## Fixed-Context Aspects and Context Adaptation

Context adaptation refers to changing the context of an existing aspect, making it provide a different set of modules.

An aspect calling `parametric.fixedTo` with an attribute set becomes a fixed or known-context aspect and can be included as if it were a static aspect without having to call it as a function.

The `parametric.expands` functor allows you to append an attribute set to whatever context is received at the call.

This example adapts an aspect by replacing its inner `__functor` twice:

```nix
a = { x, ... }: { nixos.foo = x; };
b = { x, y, ... }: { nixos.foo = y; };

# when original is used, it will only call a since b needs more context
original = parametric.fixedTo { x = 0; } { 
  includes = [ a b ];
};

# replaces the context, but it will still only invoke a.
replaced = parametric.fixedTo { x = 1; } original;

# when used, it will call both a and b, { x = 0, y = 2 }
expanded = parametric.expands { y = 2; } original;
```

## Advanced Context Handling

Note that since all `den.lib.parametric` combinators are themselves functors, the following two are exactly the same:

```nix
# recommended functional style: applying to an aspect.
parametric.atLeast {
  includes = [ a b ];
};

# attribute style: setting __functor attribute.
{
  includes = [ a b ];
  __functor = parametric.atLeast;
}
```

The first alternative is the recommended use, since it is more idiomatic and does not
surfaces knowledge about the internal `__functor`.

However, for more advanced aspects, you can provide your own `__functor` attribute.
Read the [`parametric` code](nix/lib.nix) for how to build your own.

Also, reading the [tests](templates/examples/modules/_example/ci/parametric-with-owned.nix) for these parametric functors can be of help.