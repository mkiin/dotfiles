{ lib, ... }:

{
  imports = [
    ./packages.nix
    ./hypr.nix
    ./monitors.nix
    ../../programs/matugen.nix
    ../../programs/wallust.nix
    ../../programs/wezterm.nix
    ../../programs/ghostty.nix
  ];

  programs.zsh = {
    shellAliases.qs-restart = "pkill -9 quickshell; nohup quickshell &>/dev/null & disown";
    initContent = lib.mkAfter ''
      abbr wbr="pkill -x waybar; uwsm app -- waybar &>/dev/null & disown"
    '';
  };
}
