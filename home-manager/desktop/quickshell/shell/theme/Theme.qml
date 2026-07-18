pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // ── 面（低→高） ──
    readonly property color background: Colours.background
    readonly property color inset: Colours.surfaceContainerLow
    readonly property color panel: Colours.surfaceContainer
    readonly property color card: Colours.surfaceContainerHigh
    readonly property color cardHigh: Colours.surfaceContainerHighest

    // ── 強調色とその上の文字 ──
    readonly property color primary: Colours.primary
    readonly property color onPrimary: Colours.onPrimary
    readonly property color primaryContainer: Colours.primaryContainer
    readonly property color onPrimaryContainer: Colours.onPrimaryContainer

    readonly property color secondary: Colours.secondary
    readonly property color onSecondary: Colours.onSecondary
    readonly property color secondaryContainer: Colours.secondaryContainer
    readonly property color onSecondaryContainer: Colours.onSecondaryContainer

    readonly property color tertiary: Colours.tertiary
    readonly property color onTertiary: Colours.onTertiary
    readonly property color tertiaryContainer: Colours.tertiaryContainer
    readonly property color onTertiaryContainer: Colours.onTertiaryContainer

    readonly property color error: Colours.error
    readonly property color onError: Colours.onError
    readonly property color errorContainer: Colours.errorContainer
    readonly property color onErrorContainer: Colours.onErrorContainer

    readonly property color warning: Colours.warning
    readonly property color onWarning: Colours.onWarning
    readonly property color success: Colours.success
    readonly property color onSuccess: Colours.onSuccess
    readonly property color info: Colours.info

    // ── 文字（面の上） ──
    readonly property color text: Colours.onSurface
    readonly property color textVariant: Colours.onSurfaceVariant

    // ── 線 ──
    readonly property color border: Colours.outlineVariant
    readonly property color outline: Colours.outline

    // ── 効果（不透明。濃さは利用側の opacity で与える） ──
    readonly property color shadow: Colours.shadow
    readonly property color scrim: Colours.scrim
}
