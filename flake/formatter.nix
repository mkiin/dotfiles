{
  perSystem = { config, pkgs, ... }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt = {
          enable = true;
          package = pkgs.nixfmt;
        };
        stylua.enable = true;
        shfmt.enable = true;
        qmlformat.enable = true;
      };

      settings.formatter.shfmt.includes = [ "*.zsh" ];

      settings.excludes = [
        "*.lock"
        ".git/**"
        "secrets/**"
        "home/linux/desktop/themes/wallust/templates/**"
        "home/linux/desktop/themes/matugen/templates/**"
      ];
    };
    pre-commit = {
      check.enable = false;
      settings.hooks = {
        treefmt = {
          enable = true;
          package = config.treefmt.build.wrapper;
        };
        deadnix.enable = true;
        statix.enable = false;
        convco = {
          enable = true;
          settings.configPath = pkgs.writeText "convco.json" (
            builtins.toJSON {
              types =
                map
                  (type: {
                    inherit type;
                    section = "Other";
                    hidden = true;
                  })
                  [
                    "feat" # 新しい機能や設定による振る舞いを追加する
                    "fix" # 不具合や意図しない動作を修正する
                    "chore" # 定型作業や lock ファイルの更新を行う
                    "ci" # CI のワークフローを変更する
                    "refactor" # 振る舞いを変えずに構成やコードを整理する
                    "docs" # ドキュメントだけを変更する
                    "style" # 振る舞いを変えずに書式や空白を変更する
                    "test" # テストを追加または変更する
                    "perf" # 動作を保ちながら性能を改善する
                    "build" # ビルド方法や依存関係の設定を変更する
                  ];
            }
          );
        };
      };
    };
  };
}
