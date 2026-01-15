{ ... }:
let
  timeZone = "Europe/Berlin";
  defaultLocale = "en_US.UTF-8";
  germanLocale = "de_DE.UTF-8";
in
{
  flake.modules.nixos.localization = {
    time.timeZone = timeZone;

    i18n.defaultLocale = defaultLocale;

    i18n.extraLocaleSettings = {
      LC_ADDRESS = germanLocale;
      LC_IDENTIFICATION = germanLocale;
      LC_MEASUREMENT = germanLocale;
      LC_MONETARY = germanLocale;
      LC_NAME = germanLocale;
      LC_NUMERIC = germanLocale;
      LC_PAPER = germanLocale;
      LC_TELEPHONE = germanLocale;
      LC_TIME = germanLocale;
    };

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
  };

  flake.modules.homeManager.localization = {
    home.language = {
      base = defaultLocale;
      address = germanLocale;
      monetary = germanLocale;
      measurement = germanLocale;
      name = germanLocale;
      numeric = germanLocale;
      paper = germanLocale;
      telephone = germanLocale;
      time = germanLocale;
    };

    home.keyboard = {
      layout = "us";
      variant = "";
    };
  };
}
