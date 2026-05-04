#!/usr/bin/env bash
# 独立 keybind: アプリランチャ (drun mode)

THEME="$HOME/.config/rofi/themes/launcher.rasi"

exec rofi -show drun -theme "$THEME"
