_:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true; # nixfmt-rfc-style (Nix 整形)
    statix.enable = true; # Nix lint (statix fix)
    shfmt = {
      enable = true; # sh / bash / zsh
      includes = [
        "*.sh"
        "*.bash"
        "*.zsh"
        "*.envrc"
        "*.envrc.*"
      ];
    };
    prettier = {
      enable = true; # json / md / css (spec の対象範囲に限定)
      includes = [
        "*.json"
        "*.json5"
        "*.md"
        "*.mdx"
        "*.css"
        "*.scss"
      ];
      excludes = [
        "*/lazy-lock.json" # lazy.nvim 管理の compact JSON を churn させない
        "*/matugen/templates/*" # Tera テンプレート (不正な CSS) を除外
        "*/wallust/templates/*" # wallust テンプレート ({{...}} 記法で不正な CSS/JSON) を除外
      ];
    };
    taplo.enable = true; # toml
    stylua = {
      enable = true; # lua
      excludes = [
        "*/matugen/templates/*" # Tera テンプレート (不正な Lua) を除外
        "*/wallust/templates/*" # wallust テンプレート を除外
      ];
    };
  };
}
