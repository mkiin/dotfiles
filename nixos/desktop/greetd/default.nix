{ pkgs, ... }:
{
  services.greetd.enable = true;

  programs.regreet = {
    enable = true;

    cageArgs = [
      "-s"
      "-d"
      "-m"
      "last"
    ];

    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
    font = {
      name = "Inter";
      package = pkgs.inter;
      size = 15;
    };

    settings = {
      background = {
        path = "${../../../images/login/login.png}";
        fit = "Cover";
      };
      GTK.application_prefer_dark_theme = true;
      appearance.greeting_msg = "Welcome back";
      widget.clock = {
        format = "%H:%M  %a";
        resolution = "1s";
        label_width = 180;
      };
    };

    extraCss = builtins.readFile ./style.css;
  };
}
