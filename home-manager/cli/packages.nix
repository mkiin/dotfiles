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
      glow
      eza
      jq
      fzf
      zip
      unzip
      zoxide
      # shell
      shellcheck
      shfmt
      mo
      # dev tools
      gh
      fastfetch
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
