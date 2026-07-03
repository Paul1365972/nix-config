{ ... }:
{
  den.aspects.notifications.provides.to-users.homeManager =
    { osConfig, ... }:
    let
      r = osConfig.rice.current;
    in
    {
      services.mako = {
        enable = true;
        settings = {
          font = "${r.font} 11";
          background-color = "#${r.colors.bg}";
          text-color = "#${r.colors.fg}";
          border-color = "#${r.colors.accent}";
          border-radius = 8;
          default-timeout = 8000;
        };
      };
    };
}
