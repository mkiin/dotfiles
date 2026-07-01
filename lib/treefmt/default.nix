_: {
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true; # nixfmt-rfc-style (Nix 整形)
    statix.enable = true; # Nix lint (statix fix)
    deadnix = {
      enable = true;
      no-lambda-pattern-names = true;
    };
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
      enable = true;
      includes = [
        "*.json"
        "*.json5"
        "*.md"
        "*.mdx"
        "*.css"
        "*.scss"
      ];
      excludes = [
        "*/lazy-lock.json"
        "*/matugen/templates/*"
        "*/wallust/templates/*"
      ];
    };
    taplo.enable = true;
    stylua = {
      enable = true;
      excludes = [
        "*/matugen/templates/*"
        "*/wallust/templates/*"
      ];
    };
  };
}
