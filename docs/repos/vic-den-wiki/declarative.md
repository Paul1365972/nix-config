# Declarative Systems

The first step to using Den is to declare the hosts and homes that exist in your infrastructure.

This is achieved through concise, one-liner syntax for the most common use cases. Usage is up to you; some people prefer a single `hosts.nix` file with one line per host. Urgently decommissioning a host requires only a single-line change in your repository.

## Hosts and Users

In the following example, `my-laptop` is the hostname and `vic` is the username.

```nix
den.hosts.x86_64-linux.my-laptop.users.vic = { };
```

However, you can also nest several hosts per platform or create multiple users on a single host.

You can change any of their attributes. See the [schema](modules/_types.nix) for reference.

If you expand the attribute set, we recommend using a single module per host definition.

```nix
den.hosts.x86_64-linux = {
  my-laptop = {
    hostName = "yavanna"; # default was my-laptop
    description = "lover of all things that grow on earth";
    class = "nixos"; # default is guessed from platform
    aspect = "workstation"; # default was my-laptop
    users = {
      vic = {
        description = "Victor Borja";
        userName = "vborja"; # default was vic 
        aspect = "oeiuwq"; # default was vic
        class = "homeManager"; # default is homeManager
      };
    };
  };
};
```

## Standalone Home-Manager

Similarly, home declarations are simple.

```nix
den.homes.aarch64-darwin.vic = { };
```

## Hosts, Users and Homes are `freeform` types.

You can add arbitrary custom attributes to your Host, User, and Home attribute sets. This is useful for adding metadata that aspects can later use for configuration.

For example, our [`primary-user.nix`](modules/aspects/provides/primary-user.nix) aspect can set `wsl.defaultUser` if it finds that its `{ host }` has a `wsl` attribute.

Host, User, and Home are also submodules, allowing you to go beyond freeform types and add new options that will be type-checked by the Nix module system.

## Base modules (going beyond freeform attributes)

Sometimes you might want all your hosts to have a common config option.

Den provides `den.base.{host,user,home}` modules that you can extend with your own custom options, making them available on each Host/Home/User configuration. See [tests for this](templates/examples/modules/_example/ci/base-conf-modules.nix)

## Next Step

Once you have some system definitions, you can attach configurations via aspects.