# Different Input Channels per System

At times, you may need to restrict certain hosts to specific Nixpkgs channels. For example, a WSL system might need to use the `stable` channel for Nixpkgs, Home-Manager, and NixOS-WSL.

This can be achieved by using the `instantiate` attribute. See an example [here](templates/examples/modules/_example/hosts.nix#L21).