pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "../config" as QsConfig
import "." as QsServices

Singleton {
    id: root

    // === Material 3 tokens from matugen (~/.cache/quickshell/matugen-colors.json) ===
    // 書込可トークンは loadColors() で matugen から設定。
    // on* 系（text-on-color）は QML の signal-handler 文法と衝突するため readonly 派生で公開する。

    property color background: "#101418"
    property color foreground: "#e0e2e8"
    property color cursor: "#99ccfa"

    property color primary: "#99ccfa"
    property color primaryContainer: "#084b72"
    property color secondary: "#b8c8da"
    property color secondaryContainer: "#394857"
    property color tertiary: "#d2bfe7"
    property color tertiaryContainer: "#4e4161"

    property color surface: "#101418"
    property color surfaceDim: "#101418"
    property color surfaceBright: "#36393e"
    property color surfaceContainerLowest: "#0b0f12"
    property color surfaceContainerLow: "#181c20"
    property color surfaceContainer: "#1c2024"
    property color surfaceContainerHigh: "#272a2e"
    property color surfaceContainerHighest: "#313539"
    property color surfaceVariant: "#42474e"

    property color outline: "#8c9198"
    property color outlineVariant: "#42474e"

    property color success: "#a6e3a1"
    property color warning: "#f9e2af"
    property color error: "#ffb4ab"
    property color errorContainer: "#93000a"
    property color info: "#99ccfa"

    property color inverseSurface: "#e0e2e8"
    property color inverseOnSurface: "#2d3135"
    property color inversePrimary: "#2c638b"

    property color scrim: "#000000"
    property color shadow: "#000000"

    // text-on-color（readonly 派生：on* は writable にすると signal-handler 文法に衝突するため）
    readonly property color onPrimary: background
    readonly property color onPrimaryContainer: foreground
    readonly property color onSecondary: background
    readonly property color onTertiary: background
    readonly property color onSurface: foreground
    readonly property color onSurfaceVariant: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.75)
    readonly property color onSurfaceMuted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.68)
    readonly property color onSuccess: background
    readonly property color onWarning: background
    readonly property color onError: background

    // Legacy flat palette (color0..15)
    property color color0: surface
    property color color1: error
    property color color2: tertiary
    property color color3: secondary
    property color color4: primary
    property color color5: secondary
    property color color6: tertiary
    property color color7: onSurface
    property color color8: onSurfaceVariant
    property color color9: error
    property color color10: tertiary
    property color color11: secondary
    property color color12: primary
    property color color13: secondary
    property color color14: tertiary
    property color color15: onSurface

    property var colors: ({
        color0: color0, color1: color1, color2: color2, color3: color3,
        color4: color4, color5: color5, color6: color6, color7: color7,
        color8: color8, color9: color9, color10: color10, color11: color11,
        color12: color12, color13: color13, color14: color14, color15: color15
    })

    // Compatibility aliases
    readonly property color glassLow: surfaceContainerLow
    readonly property color glassHigh: surfaceContainerHigh
    readonly property color glassHighest: surfaceContainerHighest
    readonly property color glassBorder: outlineVariant
    readonly property color glassBorderStrong: Qt.rgba(primary.r, primary.g, primary.b, 0.28)
    readonly property color stateLayerLight: Qt.rgba(foreground.r, foreground.g, foreground.b, 1)
    readonly property color stateLayerDark: Qt.rgba(background.r, background.g, background.b, 1)

    function loadColors(text: string): void {
        try {
            const d = JSON.parse(text);
            const set = (key) => { if (d[key] !== undefined && d[key] !== null) root[key] = d[key]; };

            set("background"); set("foreground"); set("cursor");
            set("primary"); set("primaryContainer");
            set("secondary"); set("secondaryContainer");
            set("tertiary"); set("tertiaryContainer");
            set("surface"); set("surfaceDim"); set("surfaceBright");
            set("surfaceContainerLowest"); set("surfaceContainerLow"); set("surfaceContainer");
            set("surfaceContainerHigh"); set("surfaceContainerHighest"); set("surfaceVariant");
            set("outline"); set("outlineVariant");
            set("success"); set("warning"); set("error"); set("errorContainer"); set("info");
            set("inverseSurface"); set("inverseOnSurface"); set("inversePrimary");
            set("scrim"); set("shadow");

            const c = d.colors;
            if (c) {
                for (let i = 0; i <= 15; i++) {
                    const k = "color" + i;
                    if (c[k] !== undefined && c[k] !== null) root[k] = c[k];
                }
                root.colors = c;
            }
            QsServices.Logger.debug("Pywal", "matugen-colors.json loaded")
        } catch (e) {
            QsServices.Logger.error("Pywal", "Failed to parse matugen-colors.json", e?.message ?? e)
        }
    }

    FileView {
        id: matugenFile
        path: QsConfig.Config.paths.pywalColors
        watchChanges: true
        onLoaded: root.loadColors(text())
        onFileChanged: root.loadColors(text())
        onLoadFailed: err => QsServices.Logger.warn("Pywal", `matugen-colors.json not loaded: ${FileViewError.toString(err)}`)
    }
}
