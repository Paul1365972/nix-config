{ ... }:
let
  defaultEditor = "hx";
  defaultBranch = "main";

  commonAliases = {
    st = "status";
    co = "checkout";
    br = "branch";
    ci = "commit";
    lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    last = "log -1 HEAD";
    unstage = "reset HEAD --";
  };
in
{
  flake.modules.nixos.git = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
    ];
  };

  flake.modules.homeManager.git = { lib, ... }: {
    programs.git = {
      enable = true;

      settings = {
        user = {
          name = lib.mkDefault "Your Name";
          email = lib.mkDefault "you@example.com";
        };

        init.defaultBranch = defaultBranch;
        core.editor = defaultEditor;

        pull.rebase = true;
        push.autoSetupRemote = true;
        rerere.enabled = true;

        diff.algorithm = "histogram";

        color.ui = "auto";

        alias = commonAliases;
      };
    };
  };
}
