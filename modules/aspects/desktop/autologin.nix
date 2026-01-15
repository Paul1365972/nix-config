{ den, ... }:
{
  # Autologin aspect - context-aware, applies when user data is available
  den.aspects.autologin =
    { user, ... }:
    {
      nixos =
        { config, lib, ... }:
        lib.mkIf config.services.greetd.enable {
          services.greetd.settings.initial_session = {
            command = config.services.greetd.settings.default_session.command;
            user = user.userName;
          };
        };
    };
}
