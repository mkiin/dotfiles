{ lib, ... }:

{
  imports = [
    ./hyprland
    ./hyprland/monitor.nix
    ./packages.nix
    ./waybar.nix
    ./quickshell.nix
    ./wlogout.nix
    ./fcitx5.nix
    ./mouse.nix
    ./services.nix
    ./apps.nix
    ../programs/matugen.nix
    ../programs/wallust.nix
    ../programs/wezterm.nix
    ../programs/ghostty.nix
  ];

  programs.zsh = {
    shellAliases.qs-restart = "pkill -9 quickshell; nohup quickshell &>/dev/null & disown";
    initContent = lib.mkAfter ''
      abbr wbr="pkill -x waybar; uwsm app -- waybar &>/dev/null & disown"
    '';
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/claude-cli"    = "claude-code-url-handler.desktop";
      "x-scheme-handler/http"          = "zen.desktop";
      "x-scheme-handler/https"         = "zen.desktop";
      "x-scheme-handler/chrome"        = "zen.desktop";
      "text/html"                      = "zen.desktop";
      "application/x-extension-htm"    = "zen.desktop";
      "application/x-extension-html"   = "zen.desktop";
      "application/x-extension-shtml"  = "zen.desktop";
      "application/xhtml+xml"          = "zen.desktop";
      "application/x-extension-xhtml"  = "zen.desktop";
      "application/x-extension-xht"    = "zen.desktop";
      "video/mp4"                      = "mpv.desktop";
    };
  };
}
