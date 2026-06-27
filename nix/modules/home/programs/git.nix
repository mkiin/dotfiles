{ config, ... }:

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
      ghq.root = "${config.home.homeDirectory}/ghq";
      credential."https://github.com".helper = [
        ""
        "!gh auth git-credential"
      ];
      credential."https://gist.github.com".helper = [
        ""
        "!gh auth git-credential"
      ];
    };
  };
}
