zle-line-init() { echo -ne '\e[2 q'; }
zle -N zle-line-init

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
