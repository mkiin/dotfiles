{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
    settings = {
      mgr = {
        show_hidden = false;
        linemode = "size";
      };
      # enter/l で画像を imv に渡す。orphan=true で yazi を閉じても残す
      opener.image = [
        {
          run = ''imv "$@"'';
          orphan = true;
          desc = "View image";
        }
      ];
      open.prepend_rules = [
        {
          mime = "image/*";
          use = "image";
        }
      ];
      plugin.prepend_fetchers = [
        {
          url = "*";
          run = "git";
          group = "git";
        }
        {
          url = "*/";
          run = "git";
          group = "git";
        }
      ];
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          on = "l";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = "<Enter>";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = "f";
          run = "plugin jump-to-char";
          desc = "Jump to a file whose name starts with the given char";
        }
        {
          on = "F";
          run = "filter --smart";
          desc = "Filter files (smart-case, no auto-enter)";
        }
        {
          on = "T";
          run = "plugin toggle-pane max-preview";
          desc = "Maximize or restore the preview pane";
        }
        {
          on = [
            "c"
            "y"
          ];
          run = ''shell 'wl-copy -t "$(xdg-mime query filetype "$0")" < "$0"' '';
          desc = "Copy hovered file content to clipboard";
        }
      ];
    };
    initLua = ''
      require("full-border"):setup()
      require("git"):setup()
    '';
    plugins = with pkgs.yaziPlugins; {
      inherit
        full-border
        git
        jump-to-char
        smart-enter
        smart-filter
        toggle-pane
        ;
    };
  };
}
