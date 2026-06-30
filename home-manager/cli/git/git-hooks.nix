{
  lib,
  inputs,
  system,
  dotfilesDir,
  ...
}:
let
  pre-commit = inputs.git-hooks.lib.${system}.run {
    src = inputs.self;
    hooks.treefmt = {
      enable = true;
      package = inputs.self.packages.${system}.fmt;
    };
  };
in
{
  home.activation.installGitHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "${dotfilesDir}/.git" ]; then
      (
        cd "${dotfilesDir}"
        rm -f "${dotfilesDir}/.git/hooks/pre-commit"
        ${pre-commit.shellHook}
      ) || echo "WARNING: git-hooks のインストールに失敗しました（switch は継続）"
    fi
  '';
}
