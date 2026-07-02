{ lib, ... }:
{
  imports = [
    ./packages.nix
    ./gtk
    ./cursor
    ./hyprland
    ./waybar
    ./cliphist
    ./hypridle
    ./quickshell
    ./wlogout
    ./fcitx5
    ./mouse
    ./matugen
    ./wallust
    ./terminal/ghostty
    ./terminal/wezterm
    ./zen
    ./vesktop
    ./games/anime-games-launcher
  ];

  programs.zsh = {
    shellAliases.qs-restart = "pkill -9 quickshell; nohup quickshell &>/dev/null & disown";
    initContent = lib.mkAfter ''
      abbr wbr="systemctl --user restart waybar"
    '';
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/chrome" = "zen-beta.desktop";
      "text/html" = "zen-beta.desktop";
      "application/x-extension-htm" = "zen-beta.desktop";
      "application/x-extension-html" = "zen-beta.desktop";
      "application/x-extension-shtml" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
      "application/x-extension-xhtml" = "zen-beta.desktop";
      "application/x-extension-xht" = "zen-beta.desktop";
      "video/mp4" = "mpv.desktop";
    };
  };
}
