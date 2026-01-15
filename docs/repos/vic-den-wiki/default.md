# One aspect to [define](modules/aspects/definition.nix) them all, and in dependencies.nix bind them.

Den uses the `den.default` aspect as a backbone for providing **shared** values, since **each** Host, User, and Home automatically includes it.

## Global Settings

You can use it to define settings that will never change.

```nix
den.default.nixos.system.stateVersion = "25.11";
den.default.darwin.system.stateVersion = 6;
den.default.homeManager.programs.vim.enable = true;
```

## Default Dependencies

`den.default` also serves as the main router for context-aware aspects, a topic we will explore in later sections.

## `default.includes`

As with any aspect, you can make `default` depend on other aspects, causing them to be included in all Homes, Users, and Hosts. This topic is also explored incrementally in the following sections.

You can also make any aspect include `den.default`, but be sure to avoid recursion.