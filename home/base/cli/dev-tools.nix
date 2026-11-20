{ pkgs, config, ... }:
let
  tsrs = pkgs.callPackage ./packages/tsrs.nix { };
in
{
  home.packages = with pkgs; [
    nodejs-slim_24
    pnpm
    # JS / TS
    typescript
    tsrs
    oxlint
    oxfmt

    # Rust
    cargo
    rustc
    rustfmt
    clippy

    # C / C++
    gcc
    clang-tools

    # Lua
    luau-lsp

    # Nix
    statix

    # Python
    ruff
    ty

    # Editor tooling
    tree-sitter

    package-version-server
  ];

  # The pinned Oxlint uses this hook to start a custom type-aware backend.
  home.sessionVariables.OXLINT_TSGOLINT_PATH = "${tsrs}/bin/tsrs-lint";

  programs.bun.enable = true;
  programs.uv.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
  };

  xdg.configFile."direnv/direnv.toml".text = ''
    [global]
    hide_env_diff = true
    log_format = "-"
  '';

  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm
    min-release-age=2
    engine-strict=true
    use-pnpm=true
  '';

  xdg.configFile."pnpm/config.yaml".text = ''
    minimumReleaseAge: 2800
  '';

  xdg.configFile."pip/pip.conf".text = ''
    [global]
    index-url = https://ftp.jaist.ac.jp/pub/PyPI/simple/
    trusted-host = ftp.jaist.ac.jp
  '';

  xdg.configFile."uv/uv.toml".text = ''
    [[index]]
    url = "https://ftp.jaist.ac.jp/pub/PyPI/simple/"
    default = true

    [[index]]
    url = "https://pypi.org/simple/"

    [[index]]
    name = "pytorch"
    url = "https://download.pytorch.org/whl/cu128"
  '';
}
