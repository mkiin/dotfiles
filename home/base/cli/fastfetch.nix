{
  config,
  myvars,
  ...
}:
{
  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      logo = {
        type = "kitty";
        source = "${config.home.homeDirectory}/${myvars.dotfilesdir}/assets/yukinoshita-yukino-crouching.png";
        height = 16;
        preserveAspectRatio = true;
        padding = {
          top = 1;
        };
        printRemaining = false;
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
          format = "";
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
        {
          type = "custom";
          format = "";
        }
      ];
    };
  };
}
