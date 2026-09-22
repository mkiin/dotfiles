{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    nodejs-slim_24
    pnpm
    # JS / TS
    oxlint
    oxfmt

    # Rust
    rust-analyzer
    rustfmt
    clippy

    # C / C++
    clang-tools

    # Lua
    lua-language-server
    stylua

    # Shell
    bash-language-server
    shellcheck
    shfmt

    # Nix
    nixd
    nixfmt
    statix

    # Python
    ruff
    ty
  ];

  programs.bun.enable = true;
  programs.uv.enable = true;

  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm
    min-release-age=2
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
