# Welcome to Den

Den is part of [vic's dendritic libs](https://vic.github.io/dendrix/Dendritic-Ecosystem.html#vics-dendritic-libraries). Its goal is to enable you to create powerful Dendritic Nix modules that are composable and reusable in your own infrastructure and by other people.

Den focuses on declaring Dendritic Nix configurations. This typically involves NixOS, nix-Darwin, and Home-Manager setups, but Den is not limited to any particular Nix configuration `class`.

Den is powered by the [`flake-aspects`](https://github.com/vic/flake-aspects) library, extending it with a dependency system for host/user configurations and providing helpers for context-aware, parametric aspects.

Den includes a small set of batteries that serve as generic aspect examples and as opt-in integrations for tools like Home-Manager or to aid migration from non-dendritic setups.


