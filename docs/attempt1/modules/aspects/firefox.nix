{ ... }:
{
  flake.modules.homeManager.firefox = {
    programs.firefox = {
      enable = true;

      profiles.default = {
        id = 0;
        isDefault = true;
        settings = {
          "browser.startup.homepage" = "about:home";
          "browser.newtabpage.enabled" = true;
        };
      };
    };
  };
}
