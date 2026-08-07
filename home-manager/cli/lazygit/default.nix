_:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui.nerdFontsVersion = "3";
      git.diffRenderers = [
        {
          colorArg = "always";
          # features を明示指定して side-by-side だけ落とす(狭いパネルで潰れるため)。テーマは残す
          command = "delta --features=gruvmax-fang --paging=never --width={{columnWidth}}";
        }
      ];
    };
  };
}
