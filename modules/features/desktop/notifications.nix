_: {
  den.aspects.notifications.provides.to-users.homeManager =
    { config, ... }:
    let
      c = config.theme.colors;
    in
    {
      services.mako = {
        enable = true;
        settings = {
          font = "${config.theme.font} 11";
          background-color = "#${c.bg}";
          text-color = "#${c.fg}";
          border-color = "#${c.accent}";
          border-radius = 8;
          default-timeout = 8000;
        };
      };
    };
}
