# --------------------------------------------
# yazi: 終了時に最後のディレクトリへ cd
# --------------------------------------------
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [[ -n $cwd && $cwd != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# --------------------------------------------
# カーソルをブロックに固定
# --------------------------------------------
zle-line-init() { echo -ne '\e[2 q'; }
zle -N zle-line-init

# --------------------------------------------
# wezterm シェル統合
# --------------------------------------------
if [[ -n $WEZTERM_PANE && -r /etc/profile.d/wezterm.sh ]]; then
  source /etc/profile.d/wezterm.sh
fi

# --------------------------------------------
# ghq + fzf: リポジトリ一覧から選んで cd
# --------------------------------------------
ghq-fzf() {
  local dir
  dir=$(ghq list -p | fzf --prompt="repositories > " --query "$LBUFFER")
  if [[ -n $dir ]]; then
    BUFFER="cd ${dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N ghq-fzf
bindkey '^g' ghq-fzf

