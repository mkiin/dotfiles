# --------------------------------------------
# VSCode Server 自動クリーンアップ
# --------------------------------------------
vscode_cleanup() {
    local VSCODE_DIR="$HOME/.vscode-server"
    local RETENTION_DAYS=3

    [[ ! -d "$VSCODE_DIR" ]] && return 0

    [[ -d "$VSCODE_DIR/data/CachedExtensionVSIXs" ]] && \
        find "$VSCODE_DIR/data/CachedExtensionVSIXs" -mindepth 1 -delete 2>/dev/null

    if [[ -d "$VSCODE_DIR/data/logs" ]]; then
        local cutoff_date=$(date -d "${RETENTION_DAYS} days ago" +%Y%m%d)
        for dir in "$VSCODE_DIR/data/logs"/202*; do
            [[ -d "$dir" ]] || continue
            local dir_date="${dir##*/}"
            dir_date="${dir_date:0:8}"
            [[ "$dir_date" -lt "$cutoff_date" ]] && rm -rf "$dir" 2>/dev/null
        done
    fi

    [[ -d "$VSCODE_DIR/data/User/workspaceStorage" ]] && \
        find "$VSCODE_DIR/data/User/workspaceStorage" -maxdepth 1 -type d -mtime +${RETENTION_DAYS} ! -name workspaceStorage -exec rm -rf {} \; 2>/dev/null

    if [[ -d "$VSCODE_DIR/data/User/History" ]]; then
        find "$VSCODE_DIR/data/User/History" -type f -mtime +${RETENTION_DAYS} -delete 2>/dev/null
        find "$VSCODE_DIR/data/User/History" -type d -empty -delete 2>/dev/null
    fi

    [[ -d "$VSCODE_DIR/data/CachedExtensions" ]] && \
        find "$VSCODE_DIR/data/CachedExtensions" -mindepth 1 -delete 2>/dev/null
    [[ -d "$VSCODE_DIR/data/CachedProfilesData" ]] && \
        find "$VSCODE_DIR/data/CachedProfilesData" -type f -mtime +${RETENTION_DAYS} -delete 2>/dev/null

    if [[ -d "$VSCODE_DIR/data/clp" ]]; then
        ls -t "$VSCODE_DIR/data/clp" 2>/dev/null | tail -n +3 | while read dir; do
            rm -rf "$VSCODE_DIR/data/clp/$dir" 2>/dev/null
        done
    fi

    if [[ -d "$VSCODE_DIR/bin" ]]; then
        ls -t "$VSCODE_DIR/bin" 2>/dev/null | tail -n +2 | while read dir; do
            [[ -d "$VSCODE_DIR/bin/$dir" ]] && rm -rf "$VSCODE_DIR/bin/$dir" 2>/dev/null
        done
    fi

    if [[ -f "$VSCODE_DIR/extensions/.obsolete" ]] && command -v jaq &>/dev/null; then
        jaq -r 'to_entries[] | select(.value == true) | .key' "$VSCODE_DIR/extensions/.obsolete" 2>/dev/null | while read ext; do
            [[ -d "$VSCODE_DIR/extensions/$ext" ]] && rm -rf "$VSCODE_DIR/extensions/$ext" 2>/dev/null
        done
        echo "{}" > "$VSCODE_DIR/extensions/.obsolete"
    fi
}

# --------------------------------------------
# Claude Code / Serena 自動クリーンアップ
# --------------------------------------------
claude_cleanup() {
    local CLAUDE_DIR="$HOME/.claude"
    local SERENA_DIR="$HOME/.serena"
    local RETENTION_DAYS=7

    if [[ -d "$CLAUDE_DIR" ]]; then
        for dir in debug shell-snapshots todos session-env file-history statsig cache; do
            [[ -d "$CLAUDE_DIR/$dir" ]] && find "$CLAUDE_DIR/$dir" -mindepth 1 -mtime +${RETENTION_DAYS} -delete 2>/dev/null
            [[ -d "$CLAUDE_DIR/$dir" ]] && find "$CLAUDE_DIR/$dir" -type d -empty -delete 2>/dev/null
        done
        [[ -d "$CLAUDE_DIR/todos" ]] && find "$CLAUDE_DIR/todos" -type f -size 2c -delete 2>/dev/null
        [[ -f "$CLAUDE_DIR/history.jsonl" ]] && rm -f "$CLAUDE_DIR/history.jsonl" 2>/dev/null
        [[ -f "$CLAUDE_DIR/stats-cache.json" ]] && rm -f "$CLAUDE_DIR/stats-cache.json" 2>/dev/null
        [[ -f "$HOME/.claude.json.backup" ]] && rm -f "$HOME/.claude.json.backup" 2>/dev/null
    fi

    if [[ -d "$SERENA_DIR/logs" ]]; then
        local cutoff_date=$(date -d "${RETENTION_DAYS} days ago" +%Y-%m-%d)
        for dir in "$SERENA_DIR/logs"/20*(N); do
            [[ -d "$dir" ]] || continue
            local dir_date="${dir##*/}"
            [[ "$dir_date" < "$cutoff_date" ]] && rm -rf "$dir" 2>/dev/null
        done
    fi
}

# --------------------------------------------
# Docker オンデマンド運用
# --------------------------------------------
dk-start() {
    if systemctl is-active --quiet docker; then
        return 0
    fi
    echo "Wake up Docker..."
    sudo service docker start
    while ! docker info > /dev/null 2>&1; do
        printf "."
        sleep 1
    done
    echo "\nDocker is ready."
}

dk-stop() {
    sudo systemctl stop docker.socket
    sudo systemctl stop docker.service
    echo "Docker stopped."
}

dk-clean() {
    dk-stop
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
    echo "Cache cleared."
}

lazydocker() {
    dk-start
    command lazydocker "$@"
    dk-stop
}

# --------------------------------------------
# yazi: 終了時に最後のディレクトリへ cd
# --------------------------------------------
y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# --------------------------------------------
# webp -> png 一括変換 (ffmpeg + fd)
# --------------------------------------------
webp2png() {
    local target="${1:-.}"
    if [[ -f "$target" ]]; then
        [[ "$target" != *.webp ]] && { echo "webp2png: not a .webp file: $target" >&2; return 1; }
        local dst="${target%.webp}.png"
        ffmpeg -y -loglevel error -i "$target" -update 1 -frames:v 1 "$dst" \
            && rm -- "$target" \
            && echo "$dst  (removed $target)"
    elif [[ -d "$target" ]]; then
        fd -e webp . "$target" -x sh -c '
            dst="${1%.webp}.png"
            ffmpeg -y -loglevel error -i "$1" -update 1 -frames:v 1 "$dst" \
                && rm -- "$1" \
                && echo "$dst  (removed $1)"
        ' _ {}
    else
        echo "webp2png: not found: $target" >&2
        return 1
    fi
}

# --------------------------------------------
# カーソルをブロックに固定
# --------------------------------------------
zle-line-init() { echo -ne '\e[2 q' }
zle -N zle-line-init

# --------------------------------------------
# wezterm シェル統合
# --------------------------------------------
if [[ -n "$WEZTERM_PANE" && -r /etc/profile.d/wezterm.sh ]]; then
    source /etc/profile.d/wezterm.sh
fi

# --------------------------------------------
# ghq + fzf: リポジトリ一覧から選んで cd
# --------------------------------------------
ghq-fzf() {
    local dir
    dir=$(ghq list -p | fzf --prompt="repositories > " --query "$LBUFFER")
    if [[ -n "$dir" ]]; then
        BUFFER="cd ${dir}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N ghq-fzf
bindkey '^g' ghq-fzf

# --------------------------------------------
# 起動時バックグラウンド処理
# --------------------------------------------
(vscode_cleanup &>/dev/null &)
