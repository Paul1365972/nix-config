# Included and Replaceable Batteries

Den includes several opt-in [`batteries`](modules/aspects/provides), which are generic aspects that serve as both examples and integrations, such as:

- `home-manager` - Integrates Home-Manager into `host`s.
- `unfree` - Enables unfree packages by name.
- `import-tree` - Imports trees of Nix files, which is particularly useful for loading non-dendritic modules and aiding in migration.
- `define-user` - Defines a user at the OS and HM levels.
- `primary-user` - Makes a user an administrator.
- `user-shell` - Sets a user's default shell.
- `inputs'` - Access to flake-parts' per-system-selected `inputs'`.
- `self'` - Access to flake-parts' per-system-selected `self'`.

All of them are currently being [CI tested](templates/examples/modules/_example/ci), and you can look at examples of their use.

Other, more powerful batteries are available via [`denful`](https://github.com/vic/denful).