{ ... }:

{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      dark = true;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "GitHub";
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "mkiin";
        email = "mkiin@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      credential."https://github.com".helper = [
        ""
        "!~/.local/share/mise/shims/gh auth git-credential"
      ];
      credential."https://gist.github.com".helper = [
        ""
        "!~/.local/share/mise/shims/gh auth git-credential"
      ];
    };
  };
}
