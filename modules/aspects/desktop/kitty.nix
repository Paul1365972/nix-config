{ ... }:
{
  den.aspects.kitty.provides.to-users.homeManager =
    { osConfig, ... }:
    let
      c = osConfig.rice.current.colors;
    in
    {
      programs.kitty = {
        enable = true;
        themeFile = null;
        font.name = osConfig.rice.current.font;
        settings = {
          background = "#${c.bg}";
          foreground = "#${c.fg}";
          cursor = "#${c.accent}";
          selection_background = "#${c.accent}";
          url_color = "#${c.alt}";
        };
      };
    };
}
