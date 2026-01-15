# Custom namespaces for organizing aspects
{ inputs, den, ... }:
{
  # Enable den angle brackets syntax: <den/home-manager>, <my/something>
  _module.args.__findFile = den.lib.__findFile;

  # Create a custom namespace for our aspects (not exposed in flake outputs)
  # This lets us do: my.helix, my.audio, etc.
  # imports = [ (inputs.den.namespace "my" false) ];
}
