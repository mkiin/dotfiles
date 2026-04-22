#!/usr/bin/env bash
# 壁紙ディレクトリをスキャンし、Walker 用の 416x234 サムネを生成。
#
# systemd user path unit (wallpaper-thumb.path) から呼ばれる想定。
# 冪等: 既存サムネが原画像より新しければスキップ。原画像が消えたら孤児サムネを削除。
#
# サイズ 416x234 = Walker matugen theme の GtkPicture 実表示 208x117 の 2x (retina)。
# -unsharp で縮小後のシャープネスを補正、-colorspace sRGB で色空間明示。
#
# Walker 実装 (walker/src/providers/mod.rs shared_image_transformer) は
# Icon パスの画像をフル decode して GdkTexture 化する。原画像のままだと
# 大きな画像で UI がもたつくため、サムネを用意して lua 側で Icon を差し替える。

set -euo pipefail

SRC="${HOME}/pictures/wallpaper"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-thumbs"
mkdir -p "$CACHE"

# find で集める: nullglob の副作用 (後続コマンドの [N] 等が glob 展開される) を回避。
# -print0 + NUL 区切りで空白/特殊文字を含むファイル名に耐性。
while IFS= read -r -d '' img; do
    name=$(basename "$img")
    thumb="$CACHE/${name%.*}.jpg"  # 拡張子統一で .jpg

    # 既存かつ原画像より新しければスキップ
    if [ -f "$thumb" ] && [ "$thumb" -nt "$img" ]; then
        continue
    fi

    # 生成: 成功時のみ mv + 完了メッセージ、失敗時は明示エラー
    if magick "$img" \
        -strip \
        -colorspace sRGB \
        -resize 416x234^ \
        -gravity center -extent 416x234 \
        -unsharp 0x0.75+0.75+0.008 \
        -quality 85 \
        -interlace Plane \
        "$thumb.tmp"; then
        mv "$thumb.tmp" "$thumb"
        echo "generated: $name"
    else
        rm -f "$thumb.tmp"
        echo "FAILED: $name" >&2
    fi
done < <(fd --max-depth 1 --type f \
    -e jpg -e jpeg -e png -e webp \
    . "$SRC" --print0)

# 孤児サムネ削除: 原画像が消えたら対応サムネも消す
while IFS= read -r -d '' thumb; do
    name=$(basename "$thumb" .jpg)
    # 任意の拡張子で原画像が存在するかチェック
    if ! compgen -G "$SRC/${name}.*" >/dev/null; then
        rm "$thumb"
        echo "removed orphan: $(basename "$thumb")"
    fi
done < <(fd --max-depth 1 --type f -e jpg . "$CACHE" --print0)
