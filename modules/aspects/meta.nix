{ ... }:
{
  flake.meta = {
    timezone = "Europe/Amsterdam";
    locale = "en_US.UTF-8";

    primaryUser = {
      name = "paul";
      fullName = "Paul1365972";
      email = "paul1365972@gmail.com";
      shell = "bash";
    };

    defaults = {
      editor = "hx";
      browser = "firefox";
      terminal = "kitty";
      fileManager = "yazi";
    };

    style = {
      borderRadius = 8;
      borderSize = 2;
      gaps = 8;
    };
  };
}
