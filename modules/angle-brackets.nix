{ den, ... }:
{
  # Enable <den/...> angle bracket syntax globally
  _module.args.__findFile = den.lib.__findFile;
}
