{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wl-clipboard
    wf-recorder
    libnotify
    grim
    slurp
  ];

  programs.satty.enable = true;

  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  services.wl-clip-persist.enable = true;
}
