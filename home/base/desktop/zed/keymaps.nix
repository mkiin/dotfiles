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
        bindings."j j" = "vim::NormalBefore";
      }

      {
        context = "VimControl && !menu";
        bindings."shift-m" = [
          "workspace::SendKeystrokes"
          "%"
        ];
      }

      {
        context = "vim_mode == normal && !menu";
        bindings = {
          "shift-u" = [
            "workspace::SendKeystrokes"
            "ctrl-r"
          ];

          "t" = null;
          "shift-t" = null;
        };
      }

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
