_:

{
  programs.sheldon = {
    enable = true;
    settings = {
      shell = "zsh";
      plugins = {
        zsh-autosuggestions = {
          github = "zsh-users/zsh-autosuggestions";
        };
        zsh-completions = {
          github = "zsh-users/zsh-completions";
        };
        zsh-abbr = {
          github = "olets/zsh-abbr";
        };
      };
    };
  };
}
