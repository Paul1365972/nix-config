{ ... }:
{
  den.aspects.autologin = {
    nixos =
      { config, lib, ... }:
      lib.mkIf config.services.greetd.enable {
        services.greetd.settings.initial_session = {
          command = config.services.greetd.settings.default_session.command;
          user = "paul";
        };
      };
  };
}
