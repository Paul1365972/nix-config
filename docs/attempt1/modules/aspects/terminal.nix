{ ... }:
let
  fontFamily = "JetBrains Mono";  # Should match fonts.nix
  fontSize = 11;
  fontWeight = 500;

  colorScheme = "Dark+";
  backgroundColor = "#1E1E1E";
  backgroundOpacity = 0.8;

  useFancyTabBar = false;
  tabMaxWidth = 24;

  paddingLeft = "1cell";
  paddingRight = "1cell";
  paddingTop = "0.5cell";
  paddingBottom = "0cell";
in
{
  flake.modules.homeManager.terminal = {
    programs.wezterm = {
      enable = true;
      extraConfig = ''
        local wezterm = require 'wezterm'
        local config = {}

        config.front_end = "Software"
        config.enable_wayland = true
        config.check_for_updates = false

        config.use_fancy_tab_bar = ${if useFancyTabBar then "true" else "false"}
        config.tab_max_width = ${toString tabMaxWidth}

        config.font = wezterm.font {
          family = '${fontFamily}',
          weight = ${toString fontWeight},
          harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
        }
        config.font_size = ${toString fontSize}
        config.color_scheme = '${colorScheme}'

        config.text_background_opacity = ${toString backgroundOpacity}
        config.background = {
          {
            source = {
              Color="${backgroundColor}",
            },
            opacity = ${toString backgroundOpacity},
            width = '100%',
            height = '100%',
          },
          {
            source = {
              Color="${backgroundColor}",
            },
            opacity = 0,
            width = '100%',
            height = '100%',
          },
        }

        config.window_padding = {
          left = '${paddingLeft}',
          right = '${paddingRight}',
          top = '${paddingTop}',
          bottom = '${paddingBottom}',
        }

        return config
      '';
    };
  };
}
