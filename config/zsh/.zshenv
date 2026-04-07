# ============================================
# 環境変数設定 (.zshenv)
# ============================================

# ユーザーID
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# mise shims
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Editor
export EDITOR="nvim"
export VISUAL="nvim"

# fcitx5 (入力メソッド)
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx

# starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

