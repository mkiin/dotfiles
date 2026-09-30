{ inputs, pkgs, ... }:
let
  fastfetch-unwrapped = pkgs.fastfetch-unwrapped.overrideAttrs {
    version = "2.69.0";
    src = inputs.fastfetch-src;
  };

  fastfetch = pkgs.fastfetch.override {
    inherit fastfetch-unwrapped;
  };
in
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
    options = [ "--cmd cd" ];
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
      "--preview-border=line"
      "--no-scrollbar"
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

      style = "full";
      inline_height = 14;
      show_help = false;
      show_tabs = false;
      show_numeric_shortcuts = false;
      show_preview = false;
      ui = {
        columns = [
          "time"
          "command"
        ];
      };
      search.filters = [
        "global"
        "directory"
      ];
    };
  };

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "noctalia";
      theme_background = false;
      truecolor = true;
      rounded_corners = true;
      terminal_sync = true;
      graph_symbol = "braille";

      shown_boxes = "cpu mem net proc";
      update_ms = 1000;

      cpu_single_graph = false;
      show_gpu_info = "Auto";
      show_coretemp = true;
      show_cpu_watts = true;
      clock_format = "%X";

      mem_graphs = true;
      show_disks = true;
      show_swap = true;

      net_auto = true;
      net_sync = true;

      proc_sorting = "memory";
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
    };
  };

  programs.fastfetch = {
    enable = true;
    package = fastfetch;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      logo = {
        type = "kitty";
        source = "${../../../assets/doro-sleeping.GIF}";
        height = 10;
        preserveAspectRatio = true;
        padding = {
          top = 3;
        };
        animationFrame = 0;
      };

      display = {
        separator = " ";
        size = {
          maxPrefix = "GB";
          spaceBeforeUnit = "always";
          binaryPrefix = "si";
        };
      };

      modules = [
        {
          type = "custom";
          format = "\n";
        }
        {
          type = "custom";
          key = "╭───────────╮";
        }
        {
          type = "title";
          key = "│ {#34}{#cyan}{icon} user    {#keys}│";
          format = "{user-name-colored}@{host-name-colored}";
        }

        {
          type = "os";
          key = "│ {#34}{#cyan}{icon} distro  {#keys}│";
          format = "{pretty-name}";
        }
        {
          type = "kernel";
          key = "│ {#35}{#cyan} kernel  {#keys}│";
          format = "{release}";
        }
        {
          type = "wm";
          key = "│ {#36}{#green}󰇄 wm      {#keys}│";
          format = "{pretty-name}";
        }
        {
          type = "de";
          key = "│ {#36}{#green}󰇄 desktop {#keys}│";
        }
        {
          type = "terminal";
          key = "│ {#31}{#green} term    {#keys}│";
          format = "{pretty-name}";
        }
        {
          type = "shell";
          key = "│ {#32}{#green} shell   {#keys}│";
          format = "{pretty-name}";
        }
        {
          type = "packages";
          key = "│ {#33}{#yellow} nix     {#keys}│";
          format = "{nix-system}";
        }
        {
          type = "cpu";
          key = "│ {#33}{#red}󰍛 cpu     {#keys}│";
          format = "{name}";
        }
        {
          type = "gpu";
          key = "│ {#35}{#red}󰢮 gpu     {#keys}│";
          hideType = "integrated";
          format = "{vendor} {name}";
        }
        {
          type = "memory";
          key = "│ {#36}{#red} memory  {#keys}│";
          format = "{used}  {#green}{#} {total}";
        }
        {
          type = "disk";
          key = "│ {#34}{#red} disk    {#keys}│";
          format = "{size-used} {#red}{#} {size-total}";
        }
        {
          type = "uptime";
          key = "│ {#33}{#magenta}󰅐 uptime  {#keys}│";
        }
        {
          type = "custom";
          key = "│ {#39} colors  {#keys}│";
          format = "{#black}{#} {#white}{#} {#red}{#} {#green}{#} {#yellow}{#} {#blue}{#} {#magenta}{#} {#cyan}{#} ";
        }
        {
          type = "custom";
          key = "╰───────────╯";
        }
      ];
    };
  };

  programs.fd.enable = true;

  home.packages = with pkgs; [
    ffmpeg
    jq
  ];

}
