{ ... }:
{
  den.aspects.autologin =
    { host, ... }:
    {
      nixos =
        { config, lib, ... }:
        lib.mkIf config.services.greetd.enable {
          services.greetd.settings.initial_session = {
            command = config.services.greetd.settings.default_session.command;
            user = host.users.${builtins.head (builtins.attrNames host.users)}.userName;
          };
        };
    };
}
