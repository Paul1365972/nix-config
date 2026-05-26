{ ... }:
{
  den.aspects.yazi.homeManager =
    { pkgs, ... }:
    {
      programs.yazi = {
        enable = true;
        enableBashIntegration = true;
        plugins = {
          inherit (pkgs.yaziPlugins)
            mount
            toggle-pane
            vcs-files
            ;
        };
      };
    };
}
