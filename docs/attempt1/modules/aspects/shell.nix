{ ... }:
let
  colorScheme = {
    primary = "#81A1C1";
    secondary = "#A3BE8C";
    warning = "#EBCB8B";
    error = "#BF616A";
  };

  commonAliases = {
    nrs = "nixos-rebuild switch --flake .#";
    nrb = "nixos-rebuild boot --flake .#";
    nrt = "nixos-rebuild test --flake .#";
    nfu = "nix flake update";

    ls = "eza --icons";
    ll = "eza -l --icons";
    la = "eza -la --icons";
    tree = "eza --tree --icons";

    rm = "rm -i";
    mv = "mv -i";
    cp = "cp -i";

    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
  };

  shellInit = ''
    export HISTSIZE=10000
    export SAVEHIST=10000
    export HISTFILE=~/.history
  '';
in
{
  flake.modules.nixos.shell = { pkgs, ... }: {
    programs.zsh.enable = true;
    programs.bash.completion.enable = true;

    environment.systemPackages = with pkgs; [
      eza
      bat
      ripgrep
      fd
      fzf
      zoxide

      starship
      direnv
      nix-direnv
    ];

    environment.shells = with pkgs; [ zsh bash ];

    programs.zsh.promptInit = "eval \"$(starship init zsh)\"";
  };

  flake.modules.homeManager.shell = { lib, ... }: {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = commonAliases;

      initContent = shellInit;

      history = {
        size = 10000;
        save = 10000;
        path = "$HOME/.zsh_history";
        ignoreDups = true;
        ignoreSpace = true;
      };

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
          "colored-man-pages"
        ];
      };
    };

    programs.bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = commonAliases;
      initExtra = shellInit;
    };

    programs.starship = {
      enable = true;

      settings = {
        format = lib.concatStrings [
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_status"
          "$nix_shell"
          "$cmd_duration"
          "$line_break"
          "$character"
        ];

        character = {
          success_symbol = "[➜](bold ${colorScheme.secondary})";
          error_symbol = "[➜](bold ${colorScheme.error})";
        };

        directory = {
          style = "bold ${colorScheme.primary}";
          truncation_length = 3;
        };

        git_branch = {
          style = "bold ${colorScheme.warning}";
        };

        git_status = {
          style = "bold ${colorScheme.error}";
        };

        nix_shell = {
          symbol = " ";
          format = "via [$symbol$state]($style) ";
          style = "bold ${colorScheme.primary}";
        };

        cmd_duration = {
          min_time = 500;
          format = "took [$duration](bold ${colorScheme.warning})";
        };
      };
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;

      colors = {
        "bg+" = "#3B4252";
        "fg+" = "#ECEFF4";
        "hl" = colorScheme.primary;
        "hl+" = colorScheme.primary;
      };
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    programs.bat = {
      enable = true;
      config = {
        theme = "Nord";
        style = "numbers,changes,header";
      };
    };
  };
}
