{ ... }:
{
  programs.zed-editor = {
    mutableUserKeymaps = false;

    userSettings = {
      vim_mode = true;
      helix_mode = false;

      vim = {
        use_smartcase_find = true;
        toggle_relative_line_numbers = true;
        highlight_on_yank_duration = 250;
      };
    };

    userKeymaps = [
      {
        context = "vim_mode == insert";
        bindings = {
          "j j" = "vim::NormalBefore";
        };
      }

      {
        context = "VimControl && !menu";
        bindings = {
          "shift-m" = [
            "workspace::SendKeystrokes"
            "%"
          ];
        };
      }

      {
        context = "Editor && mode != full";
        bindings = {
          # Emacs-like cursor movement
          "ctrl-a" = [
            "editor::MoveToBeginningOfLine"
            { stop_at_soft_wraps = false; }
          ];

          "ctrl-e" = [
            "editor::MoveToEndOfLine"
            { stop_at_soft_wraps = false; }
          ];

          "ctrl-b" = "editor::MoveLeft";
          "ctrl-f" = "editor::MoveRight";

          # deletion
          "ctrl-h" = "editor::Backspace";
          "ctrl-d" = "editor::Delete";

          "ctrl-u" = "editor::DeleteToBeginningOfLine";
          "ctrl-k" = "editor::DeleteToEndOfLine";

          "ctrl-w" = [
            "editor::DeleteToPreviousWordStart"
            {
              ignore_newlines = false;
              ignore_brackets = false;
            }
          ];
        };
      }

      {
        context = "Editor && vim_mode == normal && !menu";
        bindings = {
          "shift-u" = [
            "workspace::SendKeystrokes"
            "ctrl-r"
          ];

          # previous / next tab
          "shift-h" = "pane::ActivatePreviousItem";
          "shift-l" = "pane::ActivateNextItem";

          # leader-like mappings
          "space space" = "file_finder::Toggle";
          "space s" = "workspace::NewSearch";

          # quit / close
          "space q q" = "pane::CloseActiveItem";
          "space q o" = "pane::CloseOtherItems";
          # "space q a" = "pane::CloseAllItems";

          "space g" = [
            "task::Spawn"
            {
              task_name = "lazygit";
              reveal_target = "center";
            }
          ];
        };
      }

      {
        context = "Terminal";
        bindings = {
          "ctrl-n" = null;
          "ctrl-p" = null;
        };
      }

      {
        context = "Editor";
        bindings = {
          "ctrl-shift-h" = "workspace::ActivatePaneLeft";
          "ctrl-shift-j" = "workspace::ActivatePaneDown";
          "ctrl-shift-k" = "workspace::ActivatePaneUp";
          "ctrl-shift-l" = "workspace::ActivatePaneRight";

          "ctrl-j" = "terminal_panel::ToggleFocus";
          # "ctrl-h" = null;
          # "ctrl-l" = null;
        };
      }

      {
        context = "Dock";
        bindings = {
          "ctrl-shift-h" = "workspace::ActivatePaneLeft";
          "ctrl-shift-j" = "workspace::ActivatePaneDown";
          "ctrl-shift-k" = "workspace::ActivatePaneUp";
          "ctrl-shift-l" = "workspace::ActivatePaneRight";
        };
      }

      {
        context = "Workspace";
        bindings = {
          "ctrl-j" = "terminal_panel::ToggleFocus";
        };
      }

      {
        context = "BufferSearchBar";
        bindings = {
          # "ctrl-h" = null;
          # "ctrl-l" = null;
        };
      }
    ];
  };
}
