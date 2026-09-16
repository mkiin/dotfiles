{ pkgs, vars, ... }:
{
  home.packages = [
    pkgs.ghq
  ];

  programs.delta = {
    enable = true;
    enableGitIntegration = true;

    options = {
      line-numbers = true;
      side-by-side = true;
      navigate = true;
      # diff-so-facy = true;
      # true-color = "always";
    };
  };

  programs.gh = {
    enable = true;
  };

  programs.lazygit = {
    enable = true;
  };

  programs.git = {
    enable = true;

    lfs.enable = true;

    signing = {
      format = "ssh";
      signByDefault = true;

      # SSH署名で使用する公開鍵を固定したいなら指定
      # key = "~/.ssh/id_ed25519.pub";
    };

    settings = {
      user = {
        name = vars.username;
        inherit (vars) useremail;
      };
      # Repository creation
      init.defaultBranch = "main";

      # Editor
      core.editor = "nvim";

      # ghq
      ghq.root = "~/ghq";

      # Push
      push = {
        default = "simple";
        autoSetupRemote = true;
      };

      # Fetch
      fetch = {
        prune = true; # remote で削除されたbranchの追跡
        writeCommitGraph = true; # フェッチ時にコミットグラフを更新
      };

      # Pull / Rebase
      pull.rebase = true;

      rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
      };

      # Diff
      diff = {
        algorithm = "histogram";
        colorMoved = "default";
        mnemonicPrefix = true;
        renames = true;
      };

      # Merge
      merge.conflictStyle = "zdiff3";

      # History / branch display
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      log.date = "iso";

      # Conflict reuse
      rerere = {
        enabled = true;
        autoupdate = true;
      };

      # Typo handling
      help.autocorrect = "prompt";

      # Commit diffをcommit message編集時に表示
      commit.verbose = true;
    };

    ignores = [
      ".DS_Store"
      ".direnv"
      ".env"
      ".venv"

      "*.swp"
      "*~"

      "__pycache__/"
      ".pytest_cache/"

      "node_modules"

      "**/.claude/settings.local.json"
      "**/.claude/worktrees"
      "**/CLAUDE.local.md"
    ];
  };
}
