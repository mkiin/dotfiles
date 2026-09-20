{ ... }:
{
  programs.quickshell = {
    enable = true;
    systemd.enable = true;
    activeConfig = "shell";
    configs = {
      shell = ./shell;
    };
  };

  xdg.configFile."quickshell/shell.json".source = ./shell.json;
}
