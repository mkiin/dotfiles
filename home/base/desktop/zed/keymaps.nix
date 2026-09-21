{ ... }:
{
  programs.zed-editor = {
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
        context = "Editor && vim_mode == normal && !menu";
        bindings = {
          "shift-u" = [
            "workspace::SendKeystrokes"
            "ctrl-r"
          ];

          # previous / next tab
          "shift-h" = "pane::ActivatePreviousItem";
          "shift-l" = "pane::ActivateNextItem";
        };
      }

      {
        context = "Editor";
        bindings = {
          "ctrl-shift-h" = "workspace::ActivatePaneLeft";
          "ctrl-shift-j" = "workspace::ActivatePaneDown";
          "ctrl-shift-k" = "workspace::ActivatePaneUp";
          "ctrl-shift-l" = "workspace::ActivatePaneRight";

          "ctrl-h" = null;
          "ctrl-j" = null;
          "ctrl-l" = null;
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
          "alt-j" = "terminal_panel::ToggleFocus";
        };
      }

      {
        context = "BufferSearchBar";
        bindings = {
          "ctrl-h" = null;
          "ctrl-l" = null;
        };
      }
    ];
  };
}
