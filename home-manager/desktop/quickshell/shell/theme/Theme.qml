pragma Singleton

import Quickshell
import QtQuick
import "." as QsTheme

Singleton {
    // ── 面（低→高） ──
    readonly property color background: QsTheme.Colours.background
    readonly property color inset: QsTheme.Colours.surfaceContainerLow
    readonly property color panel: QsTheme.Colours.surfaceContainer
    readonly property color card: QsTheme.Colours.surfaceContainerHigh
    readonly property color cardHigh: QsTheme.Colours.surfaceContainerHighest

    // ── 強調色とその上の文字 ──
    readonly property color primary: QsTheme.Colours.primary
    readonly property color _onPrimary: QsTheme.Colours._onPrimary
    readonly property color primaryContainer: QsTheme.Colours.primaryContainer
    readonly property color _onPrimaryContainer: QsTheme.Colours._onPrimaryContainer

    readonly property color secondary: QsTheme.Colours.secondary
    readonly property color _onSecondary: QsTheme.Colours._onSecondary
    readonly property color secondaryContainer: QsTheme.Colours.secondaryContainer
    readonly property color _onSecondaryContainer: QsTheme.Colours._onSecondaryContainer

    readonly property color tertiary: QsTheme.Colours.tertiary
    readonly property color _onTertiary: QsTheme.Colours._onTertiary
    readonly property color tertiaryContainer: QsTheme.Colours.tertiaryContainer
    readonly property color _onTertiaryContainer: QsTheme.Colours._onTertiaryContainer

    readonly property color error: QsTheme.Colours.error
    readonly property color _onError: QsTheme.Colours._onError
    readonly property color errorContainer: QsTheme.Colours.errorContainer
    readonly property color _onErrorContainer: QsTheme.Colours._onErrorContainer

    readonly property color warning: QsTheme.Colours.warning
    readonly property color _onWarning: QsTheme.Colours._onWarning
    readonly property color success: QsTheme.Colours.success
    readonly property color _onSuccess: QsTheme.Colours._onSuccess
    readonly property color info: QsTheme.Colours.info

    // ── 文字（面の上） ──
    readonly property color text: QsTheme.Colours._onSurface
    readonly property color textVariant: QsTheme.Colours._onSurfaceVariant

    // ── 線 ──
    readonly property color border: QsTheme.Colours.outlineVariant
    readonly property color outline: QsTheme.Colours.outline

    // ── ガラス面（matugen 非依存の固定値。waybar style.nix の glassTint / glassBorder と同値） ──
    readonly property color glassTint: Qt.rgba(10 / 255, 12 / 255, 18 / 255, 0.58)
    readonly property color glassBorder: Qt.rgba(1, 1, 1, 0.08)

    // ── 効果（不透明。濃さは利用側の opacity で与える） ──
    readonly property color shadow: QsTheme.Colours.shadow
    readonly property color scrim: QsTheme.Colours.scrim

    // ── State layer ──
    // 面の上に重ねる強度。重ねる色は各部品が自分の面に対応する on-color を渡す。
    readonly property real stateHovered: 0.08
    readonly property real statePressed: 0.12
}
