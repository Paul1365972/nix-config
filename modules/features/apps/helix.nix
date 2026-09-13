_: {
  den.aspects.helix.homeManager = {
    programs.helix = {
      enable = true;

      settings = {
        theme = "dark_plus";

        editor = {
          line-number = "relative";
          cursorline = true;
          idle-timeout = 100;
          completion-trigger-len = 1;
          true-color = true;
          undercurl = true;
          rulers = [ 120 ];
          color-modes = true;

          statusline = {
            left = [
              "mode"
              "spinner"
              "file-name"
              "read-only-indicator"
              "file-modification-indicator"
            ];
            center = [ ];
            right = [
              "selections"
              "primary-selection-length"
              "register"
              "separator"
              "position"
              "position-percentage"
              "total-line-numbers"
              "separator"
              "file-encoding"
              "file-line-ending"
              "file-type"
              "separator"
              "diagnostics"
              "workspace-diagnostics"
              "version-control"
            ];
            separator = "┆";
            mode = {
              normal = "NORMAL";
              insert = "INSERT";
              select = "SELECT";
            };
          };

          lsp = {
            display-messages = true;
            display-inlay-hints = true;
          };

          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };

          indent-guides = {
            render = true;
            character = "┊";
          };

          gutters.layout = [
            "diagnostics"
            "spacer"
            "line-numbers"
            "spacer"
            "diff"
          ];
        };

        keys.normal = {
          A-d = "delete_selection";
          d = "delete_selection_noyank";
          A-c = "change_selection";
          c = "change_selection_noyank";
        };
      };

      languages = {
        language-server = {
          nixd = {
            command = "nixd";
            config.nixd.formatting.command = [ "nixfmt" ];
          };
          rust-analyzer.config.check.command = "clippy";
        };

        language = [
          {
            name = "nix";
            language-servers = [ "nixd" ];
            formatter.command = "nixfmt";
            auto-format = true;
          }
        ];
      };
    };
  };
}
