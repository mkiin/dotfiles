{ config, pkgs, ... }:

let
  # delta 本体は themes.gitconfig を install しないため src から抜き出す(src 4.4MiB を closure に残さない)
  deltaThemes = pkgs.runCommand "delta-themes.gitconfig" { } ''
    cp ${pkgs.delta.src}/themes.gitconfig $out
  '';
in
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      # features は後勝ち。side-by-side が行番号スタイルを既定に戻すのでテーマを後ろに置く
      features = "side-by-side gruvmax-fang";
    };
  };

  programs.git = {
    enable = true;
    # dark/syntax-theme/line-numbers/diff 配色は gruvmax-fang フィーチャが持つ
    includes = [ { path = "${deltaThemes}"; } ];
    settings = {
      user = {
        name = "mkiin";
        email = "mkiin@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      ghq.root = "${config.home.homeDirectory}/ghq";
      url."git@github.com:".insteadOf = "https://github.com/";
      credential."https://github.com".helper = [
        ""
        "!gh auth git-credential"
      ];
      credential."https://gist.github.com".helper = [
        ""
        "!gh auth git-credential"
      ];
    };

    ignores = [
      # Environment
      ".venv"
      ".direnv"

      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "Icon"
      "._*"
      ".DocumentRevisions-V100"
      ".fseventsd"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".VolumeIcon.icns"
      ".com.apple.timemachine.donotpresent"
      ".AppleDB"
      ".AppleDesktop"
      "Network Trash Folder"
      "Temporary Items"
      ".apdisk"

      # Python
      "__pycache__/"
      "*.py[cod]"
      "*$py.class"
      "*.so"
      ".Python"
      "build/"
      "develop-eggs/"
      "dist/"
      "downloads/"
      "eggs/"
      ".eggs/"
      "lib64/"
      "parts/"
      "sdist/"
      "var/"
      "wheels/"
      "pip-wheel-metadata/"
      "share/python-wheels/"
      "*.egg-info/"
      ".installed.cfg"
      "*.egg"
      "MANIFEST"
      "*.manifest"
      "*.spec"
      "pip-log.txt"
      "pip-delete-this-directory.txt"
      "htmlcov/"
      ".tox/"
      ".nox/"
      ".coverage"
      ".coverage.*"
      ".cache"
      "nosetests.xml"
      "coverage.xml"
      "*.cover"
      "*.py,cover"
      ".hypothesis/"
      ".pytest_cache/"
      "*.mo"
      "*.pot"
      "*.log"
      "local_settings.py"
      "db.sqlite3"
      "db.sqlite3-journal"
      "instance/"
      ".webassets-cache"
      ".scrapy"
      "docs/_build/"
      "target/"
      ".ipynb_checkpoints"
      "profile_default/"
      "ipython_config.py"
      ".python-version"
      "__pypackages__/"
      "celerybeat-schedule"
      "celerybeat.pid"
      "*.sage.py"
      ".env"
      "env/"
      "venv/"
      "ENV/"
      "env.bak/"
      "venv.bak/"
      ".spyderproject"
      ".spyproject"
      ".ropeproject"
      "/site"
      ".mypy_cache/"
      ".dmypy.json"
      "dmypy.json"
      ".pyre/"

      # Claude Code
      "**/.claude/settings.local.json"
      "**/.claude/worktrees"
      "**/CLAUDE.local.md"
    ];
  };
}
