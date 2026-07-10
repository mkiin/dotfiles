{ pkgs, inputs, ... }:

{
  home.packages =
    with pkgs;
    [
      # essentials
      curl
      ghq
      # search & file utilities
      ripgrep
      fd
      bat
      eza
      jq
      fzf
      zoxide
      # shell
      shellcheck
      shfmt
      mo
      # dev tools
      gh
      lazydocker
      mise
      # codex の workspace-write サンドボックスが要求する bwrap 本体
      bubblewrap
    ]
    ++ [
      # agent 向けターミナルマルチプレクサ（自前 flake を参照）
      inputs.herdr.packages.${pkgs.system}.default
    ];
}
