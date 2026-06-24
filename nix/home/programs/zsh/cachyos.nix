{ ... }:

{
  programs.zsh = {
    shellAliases = {
      qs-restart = "pkill -9 quickshell; nohup quickshell &>/dev/null & disown";
    };
    initContent = ''
      abbr wbr="pkill -x waybar; uwsm app -- waybar &>/dev/null & disown"
    '';
  };
}
