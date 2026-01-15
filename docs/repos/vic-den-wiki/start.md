# Getting Started

The quickest way to get started is by using our [`default`](templates/default) template.


```console
mkdir my-den && cd my-den
nix flake init -t github:vic/den
nix flake update den
```

After initializing it, edit the annotated [`modules/den.nix`](templates/default/modules/den.nix) file. We have made the `den.nix` file self-explanatory and interesting. You can also read about Den basics or other advanced topics.

Your new `den` includes a runnable virtual machine, so you can edit the configuration and run the VM to test if things work, instead of having to reboot constantly.

Run the vm with:

```console
nix run .#vm
```

It also includes a GitHub action. We will soon provide an easy way to integrate scheduled updates using your own cachix cache. This way you won't need to re-build locally things that can be built on your CI.

