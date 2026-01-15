# Context Data Instead of `specialArgs`

Since (functional) aspects can take Host, User, and Home data via their context (arguments), there is no need to use `specialArgs` in configurations.

```nix
{ user, host }: {
  nixos = ...; # use host data
  homeManager = ...; # use user data
}
```

However, at times you may have no other option. For example, if you want a standalone Home-Manager to have access to the `osConfig` of a particular host, you can [achieve it](https://github.com/vic/den/discussions/32) by specifying a custom `instantiate` attribute on the `home` object. Be warned that using `specialArgs` is an anti-pattern in Dendritic and should be avoided unless absolutely necessary.

