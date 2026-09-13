_: {
  den.aspects.kitty.provides.to-users.homeManager =
    { config, ... }:
    let
      c = config.theme.colors;
    in
    {
      programs.kitty = {
        enable = true;
        themeFile = null;
        font.name = config.theme.font;
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
