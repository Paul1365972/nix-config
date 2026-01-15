# Shareable Aspects (Namespaces)

Namespaces are a Den social feature. It allows many flakes
to augment a given aspect tree (under the same `namespace`).

You enable namespaces by having a module like:

```nix
{ inputs, ... }: 
{
  imports = [

    # create local `eg` -example!- namespace. false: not flake exposed.
    (inputs.den.namespace "eg" false)

    # you can have several namespaces, true: exposes flake.denful.yours
    (input.den.namespace "yours" true)

    # you can also mixin from several inputs
    # just keep in mind that a namespace can be
    # defined only once, use an array as argument:
    (input.den.namespace "ours" [ true inputs.mine inputs.theirs ])
  ];
}
```

Internally, a namespace is just a `provides` branch:

```nix
# den.ful is the social-convention for namespaces.
den.ful.<namespace>.<aspect>
```

Having an aspect namespace is not required but helps a lot
with organization and conventient access to your aspects.

The following examples use the `vix` namespace,
inspired by `github:vic/vix` own namespace pattern.

By using an aspect namespace you can:

- Directly write to aspects in your namespace.

```nix
{
  vix.gaming.nixos = ...;
}
```

- Directly read aspects from your namespace.

```nix
# Access the namespace from module args
{ vix, ... }:
{
  den.default.includes = [ vix.security ];
}
```

- Share and re-use aspects between Dendritic flakes

```nix
imports = [
  # Aspects opt-in exposed as flake.denful.<name>
  ( inputs.den.namespace "vix" true)

  # Merge aspects from many sources. Use an array.
  ( inputs.den.namespace "vix" [ true inputs.dendrix ] )
];
```

- Use Den angle-brackets to access deeply nested trees

```nix
{ __findFile, ... }:
  den.aspects.my-laptop.includes = [ 
    <vix/gaming/retro> 
    
    # instead of den.ful.vix.gaming.provides.retro
  ];
}
```