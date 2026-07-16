_:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui.nerdFontsVersion = "3";
      git.pagers = [
        {
          colorArg = "always";
          pager = "delta --features=none --paging=never --width={{columnWidth}}";
        }
      ];
    };
  };
}
