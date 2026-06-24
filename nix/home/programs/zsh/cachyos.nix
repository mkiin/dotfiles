{ lib, ... }:

{
  programs.zsh = {
    shellAliases = {
      open       = "y";
      qs-restart = "pkill -9 quickshell; nohup quickshell &>/dev/null & disown";
    };
    initContent = lib.mkAfter ''
      abbr wbr="pkill -x waybar; uwsm app -- waybar &>/dev/null & disown"
    '';
  };
}
