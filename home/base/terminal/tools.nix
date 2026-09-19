{ pkgs, ... }:
{
  # replace cat
  programs.bat = {
    enable = true;

    config = {
      pager = "less -FR";
      style = "numbers,changes,header";
    };

    extraPackages = with pkgs.bat-extras; [
      batgrep
      batman
    ];
  };

  # replace ls
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = false;
    git = true;
    icons = "auto";
  };

  # replace cd
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # fuzzy searcher
  # fuzzy search directory, file
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    historyWidget.command = "";

    fileWidget.zsh = {
      command = "fd --type f --hidden --follow --exclude .git";
      options = [
        "--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
      ];
    };

    changeDirWidget = {
      command = "fd --type d --hidden --follow --exclude .git";
      options = [ "--preview 'eza --tree --level=2 --icons=auto {} | head -200'" ];
    };

    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border"
    ];
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--smart-case"
      "--hidden"
      "--glob=!.git/*"
    ];
  };

  # command history manager
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    settings = {
      auto_sync = false;
      search_mode = "fuzzy";
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "directory";
      enter_accept = false;
    };
  };

  programs = {
    fd.enable = true;
  };

  home.packages = with pkgs; [
    ffmpeg
    jq
  ];

}
