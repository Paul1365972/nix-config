{ ... }:
{
  # Exposes `flake.debug.options` (merged option tree). Required for nixd's
  # `flake-parts` introspection in modules/aspects/helix.nix.
  debug = true;
}
