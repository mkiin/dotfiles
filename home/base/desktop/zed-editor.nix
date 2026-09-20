{ lib, ... }:
{
  programs.zed-editor = {
    enable = true;
    mutableUserSettings = true;

    extensions = [
      "kanagawa-themes"
      "oxc"
      "dockerfile"
      "just"
      "nix"
      "nu"
      "terraform"
      "toml"
    ];

    userSettings = {
      # Theme
      theme = "Kanagawa Wave";

      # Vim
      vim_mode = true;
      helix_mode = false;

      # Language-specific settings
      languages = {
        # TypeScript / JavaScript
        TypeScript = {
          format_on_save = "on";
          prettier.allowed = false;

          formatter = [
            {
              language_server.name = "oxfmt";
            }
            {
              code_action = "source.fixAll.oxc";
            }
          ];

          language_servers = [
            "typescript-language-server"
            "oxlint"
            "oxfmt"
            "!eslint"
          ];
        };

        TSX = {
          format_on_save = "on";
          prettier.allowed = false;

          formatter = [
            {
              language_server.name = "oxfmt";
            }
            {
              code_action = "source.fixAll.oxc";
            }
          ];

          language_servers = [
            "typescript-language-server"
            "oxlint"
            "oxfmt"
            "!eslint"
          ];
        };

        JavaScript = {
          format_on_save = "on";
          prettier.allowed = false;

          formatter = [
            {
              language_server.name = "oxfmt";
            }
            {
              code_action = "source.fixAll.oxc";
            }
          ];

          language_servers = [
            "typescript-language-server"
            "oxlint"
            "oxfmt"
            "!eslint"
          ];
        };

        JSX = {
          format_on_save = "on";
          prettier.allowed = false;

          formatter = [
            {
              language_server.name = "oxfmt";
            }
            {
              code_action = "source.fixAll.oxc";
            }
          ];

          language_servers = [
            "typescript-language-server"
            "oxlint"
            "oxfmt"
            "!eslint"
          ];
        };

        # Rust
        Rust = {
          hard_tabs = false;
          format_on_save = "on";
          formatter.language_server.name = "rust-analyzer";

          language_servers = [
            "rust-analyzer"
            "!rustc"
          ];
        };

        # C / C++
        C = {
          format_on_save = "on";
          formatter.language_server.name = "clangd";
          language_servers = [ "clangd" ];
        };

        "C++" = {
          format_on_save = "on";
          formatter.language_server.name = "clangd";
          language_servers = [ "clangd" ];
        };

        # Lua
        Lua = {
          format_on_save = "on";

          formatter.external = {
            command = "stylua";
            arguments = [ "-" ];
          };
        };

        # Shell
        Shell = {
          format_on_save = "on";

          formatter.external = {
            command = "shfmt";
            arguments = [ ];
          };

          language_servers = [
            "bash-language-server"
          ];
        };

        # JSON
        JSON = {
          format_on_save = "on";
          prettier.allowed = false;
          formatter.language_server.name = "oxfmt";
        };

        JSONC = {
          format_on_save = "on";
          prettier.allowed = false;
          formatter.language_server.name = "oxfmt";
        };

        # Nix
        Nix = {
          format_on_save = "on";

          formatter.external = {
            command = "nixfmt";
            arguments = [ ];
          };

          language_servers = [
            "nixd"
          ];
        };

        # Python - secondary use
        Python = {
          format_on_save = "on";
          formatter.language_server.name = "ruff";

          language_servers = [
            "ty"
            "ruff"
            "!basedpyright"
            "!pyrefly"
            "!pyright"
            "!pylsp"
          ];
        };
      };

      # LSP configuration
      lsp = {
        oxlint = {
          initialization_options = {
            settings = {
              run = "onType";
              fixKind = "safe_fix";
              disableNestedConfig = false;
              unusedDisableDirectives = "deny";
            };
          };
        };

        oxfmt = {
          initialization_options = {
            settings = {
              run = "onSave";
            };
          };
        };

        rust-analyzer = {
          initialization_options = {
            check = {
              command = "clippy";
            };
          };
        };
      };

      # Terminal
      terminal.shell.with_arguments = {
        program = "bash";
        args = [
          "--login"
          "-c"
          "nu --login --interactive"
        ];
      };

      # Editor behavior
      auto_signature_help = true;
      autosave = "on_focus_change";
      code_lens = "on";
      completion_menu_item_kind = "symbol";
      completions.lsp_fetch_timeout_ms = 2000;

      diagnostics.inline.enabled = true;
      document_folding_ranges = "off";
      inlay_hints.enabled = true;

      minimap.show = "auto";
      relative_line_numbers = "enabled";
      semantic_tokens = "combined";
      soft_wrap = "editor_width";
      vertical_scroll_margin = 10.0;
      which_key.enabled = true;

      indent_guides = {
        background_coloring = "indent_aware";
        coloring = "indent_aware";
      };

      # Search
      search.regex = false;
      use_smartcase_search = true;

      # Prettier is deliberately not the main formatter
      prettier.allowed = false;

      # UI
      tabs = {
        file_icons = true;
        git_status = true;
      };

      title_bar = {
        show_branch_status_icon = true;
        show_menus = false;
        show_user_menu = true;
      };

      # Git
      git.inline_blame.show_commit_summary = true;

      # Fonts
      ui_font_family = lib.mkDefault "LXGW WenKai Screen";
      ui_font_size = lib.mkDefault 16.0;

      buffer_font_family = lib.mkDefault "Maple Mono NF CN";
      buffer_font_size = lib.mkDefault 14.0;

      agent_ui_font_size = lib.mkDefault 16.0;
      agent_buffer_font_size = lib.mkDefault 15.0;

      # Application
      auto_update = false;
      cli_default_open_behavior = "existing_window";

      # Agent
      agent.play_sound_when_agent_done = "when_hidden";

      agent_servers = {
        opencode.type = "registry";
        codex-acp.type = "registry";
      };

      # Privacy
      edit_predictions.allow_data_collection = "no";

      telemetry = {
        diagnostics = false;
        metrics = false;
      };
    };

    userKeymaps = [
      # jj -> normal mode
      {
        context = "vim_mode == insert";
        bindings = {
          "j j" = "vim::NormalBefore";
        };
      }

      # Custom normal mode behavior
      {
        context = "vim_mode == normal && !menu";
        bindings = {
          # U -> redo
          "shift-u" = [
            "workspace::SendKeystrokes"
            "ctrl-r"
          ];

          # M -> %
          "shift-m" = [
            "workspace::SendKeystrokes"
            "%"
          ];

          # Disable t / T
          "t" = null;
          "shift-t" = null;
        };
      }

      # Ctrl-w hjkl across Zed docks/panes
      {
        context = "Dock";
        bindings = {
          "ctrl-w h" = "workspace::ActivatePaneLeft";
          "ctrl-w j" = "workspace::ActivatePaneDown";
          "ctrl-w k" = "workspace::ActivatePaneUp";
          "ctrl-w l" = "workspace::ActivatePaneRight";
        };
      }
    ];
  };
}
