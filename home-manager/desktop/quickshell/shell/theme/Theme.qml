pragma Singleton

import Quickshell
import QtQuick

// 意味色トークンの単一定義層。全コンポーネントはここだけを参照する。
// alpha 合成はしない。透過が要る箇所は要素側の opacity / shadowOpacity で表す。
// 文字色は text と textVariant の 2 段だけ。3 段目を作らない。
Singleton {
    id: root

    readonly property var p: Colours

    // ── 面（低→高） ──
    readonly property color background: p.background
    readonly property color inset: p.surfaceContainerLow
    readonly property color panel: p.surfaceContainer
    readonly property color card: p.surfaceContainerHigh
    readonly property color cardHigh: p.surfaceContainerHighest

    // ── 強調色とその上の文字 ──
    readonly property color primary: p.primary
    readonly property color onPrimary: p.onPrimary
    readonly property color primaryContainer: p.primaryContainer
    readonly property color onPrimaryContainer: p.onPrimaryContainer

    readonly property color secondary: p.secondary
    readonly property color onSecondary: p.onSecondary
    readonly property color secondaryContainer: p.secondaryContainer
    readonly property color onSecondaryContainer: p.onSecondaryContainer

    readonly property color tertiary: p.tertiary
    readonly property color onTertiary: p.onTertiary
    readonly property color tertiaryContainer: p.tertiaryContainer
    readonly property color onTertiaryContainer: p.onTertiaryContainer

    readonly property color error: p.error
    readonly property color onError: p.onError
    readonly property color errorContainer: p.errorContainer
    readonly property color onErrorContainer: p.onErrorContainer

    readonly property color warning: p.warning
    readonly property color onWarning: p.onWarning
    readonly property color success: p.success
    readonly property color onSuccess: p.onSuccess
    readonly property color info: p.info

    // ── 文字（面の上） ──
    readonly property color text: p.onSurface
    readonly property color textVariant: p.onSurfaceVariant

    // ── 線 ──
    readonly property color border: p.outlineVariant
    readonly property color outline: p.outline

    // ── 効果（不透明。濃さは利用側の opacity で与える） ──
    readonly property color shadow: p.shadow
    readonly property color scrim: p.scrim
}
