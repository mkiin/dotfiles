{
  lib,
  inputs,
  system,
  dotfilesDir,
  ...
}:
let
  # cachix git-hooks.nix にフック本体を生成させる（手書きの stash/pop は不安定で、
  # 過去に stash pop コンフリクトを起こしたため廃止）。treefmt は自前の wrapper を流用。
  pre-commit = inputs.git-hooks.lib.${system}.run {
    src = inputs.self;
    hooks.treefmt = {
      enable = true;
      package = inputs.self.packages.${system}.fmt;
    };
  };
in
{
  # home-manager switch のたびに、生成された pre-commit フックを dotfiles リポジトリへ設置する。
  # devShell / direnv に依存せず、switch を実行するだけで配線される。
  # 設置スクリプトは .pre-commit-config.yaml（nix store への gc-root シンボリックリンク）を作り、
  # pre-commit install を実行する。失敗しても switch 全体は止めない。
  home.activation.installGitHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "${dotfilesDir}/.git" ]; then
      (
        cd "${dotfilesDir}"
        # 旧・手書きフックが残っていれば撤去（pre-commit install の migration 警告を避ける）。
        rm -f "${dotfilesDir}/.git/hooks/pre-commit"
        ${pre-commit.shellHook}
      ) || echo "WARNING: git-hooks のインストールに失敗しました（switch は継続）"
    fi
  '';
}
