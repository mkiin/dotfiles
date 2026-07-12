pragma Singleton

import Quickshell
import QtQuick
import "../services" as QsServices

// 意味色トークンの単一定義層。プリミティブ(Colours=matugen)から派生し、全コンポーネントはここだけを参照する。
// 面(panel/card/inset)やアクセントの割当を変えたいときはこのファイルだけ直せば全UIに伝播する。
Singleton {
    id: root

    readonly property var p: QsServices.Colours

    // ── Surfaces (elevation 低→高) ──
    readonly property color background: p.background
    readonly property color inset: p.surfaceContainerLow       // 凹んだリスト域
    readonly property color panel: p.surfaceContainer          // パネル背景 (waybar と同色)
    readonly property color card: p.surfaceContainerHigh       // カード/タイル/トースト/通知アイテム
    readonly property color cardHigh: p.surfaceContainerHighest // ホバー/最上位

    // ── Text (on surface) ──
    readonly property color text: p.foreground
    readonly property color textVariant: p.onSurfaceVariant
    readonly property color textMuted: p.onSurfaceMuted
    readonly property color textDim: withAlpha(p.foreground, 0.5)

    // ── Accent ──
    readonly property color accent: p.primary
    readonly property color secondary: p.secondary
    readonly property color tertiary: p.tertiary
    readonly property color onAccent: p.background

    // ── State ──
    readonly property color error: p.error
    readonly property color warning: p.warning
    readonly property color success: p.success
    readonly property color info: p.info

    // ── Lines ──
    readonly property color border: p.outlineVariant
    readonly property color outline: p.outline
    readonly property color borderFaint: withAlpha(p.foreground, 0.08)

    // ── Interaction / Effects ──
    readonly property color hover: withAlpha(p.foreground, 0.06)
    readonly property color shadow: p.shadow

    // alpha 付き派生用ヘルパ
    function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    // 任意のアクセント色上の可読な前景色 (輝度で自動コントラスト)
    function onColor(c) {
        return (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) > 0.55
            ? Qt.rgba(0.05, 0.06, 0.08, 1) : Qt.rgba(1, 1, 1, 1)
    }
}
