{ lib, ... }:
let
  palettes = {
    tokyo = {
      colors = {
        bg = "1a1b26";
        fg = "c0caf5";
        accent = "7aa2f7";
        alt = "bb9af7";
      };
    };
    kanagawa = {
      colors = {
        bg = "1f1f28";
        fg = "dcd7ba";
        accent = "7e9cd8";
        alt = "957fb8";
      };
    };
    rosepine = {
      colors = {
        bg = "191724";
        fg = "e0def4";
        accent = "c4a7e7";
        alt = "ebbcba";
      };
    };
  };
in
{
  den.aspects.theme.provides.to-users.homeManager =
    { config, pkgs, ... }:
    {
      options.theme = {
        palette = lib.mkOption {
          type = lib.types.enum (lib.attrNames palettes);
          default = "tokyo";
        };
        colors = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default = palettes.${config.theme.palette}.colors;
        };
        font = lib.mkOption {
          type = lib.types.str;
          default = "JetBrainsMono Nerd Font";
        };
      };

      config = {
        fonts.fontconfig.enable = true;
        home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      };
    };
}
