# Custom Factories for Any Nix Class

Den natively supports `nixos`, `darwin`, and `homeManager` configurations. However, any `host` can use a custom `instantiate` function to [build](modules/config.nix) its configuration. It is also possible to customize the `intoAttr` attribute to specify where the configuration should be placed.