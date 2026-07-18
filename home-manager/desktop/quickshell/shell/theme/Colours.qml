pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import "../config" as QsConfig
import "../utils" as QsUtils

// matugen が書き出す M3 トークンをそのまま保持する層。ここでは色を加工しない。
// 意味づけは Theme が行う。フォールバック値は matugen 未生成時の初回起動用。
Singleton {
    id: root

    property color background: "#101418"

    property color primary: "#99ccfa"
    property color onPrimary: "#003353"
    property color primaryContainer: "#084b72"
    property color onPrimaryContainer: "#cde5ff"

    property color secondary: "#b8c8da"
    property color onSecondary: "#233240"
    property color secondaryContainer: "#394857"
    property color onSecondaryContainer: "#d4e4f6"

    property color tertiary: "#d2bfe7"
    property color onTertiary: "#372b4a"
    property color tertiaryContainer: "#4e4161"
    property color onTertiaryContainer: "#eddcff"

    property color surface: "#101418"
    property color surfaceDim: "#101418"
    property color surfaceBright: "#36393e"
    property color surfaceContainerLowest: "#0b0f12"
    property color surfaceContainerLow: "#181c20"
    property color surfaceContainer: "#1c2024"
    property color surfaceContainerHigh: "#272a2e"
    property color surfaceContainerHighest: "#313539"
    property color surfaceVariant: "#42474e"

    property color onSurface: "#e0e2e8"
    property color onSurfaceVariant: "#c2c7ce"

    property color outline: "#8c9198"
    property color outlineVariant: "#42474e"

    property color error: "#ffb4ab"
    property color onError: "#690005"
    property color errorContainer: "#93000a"
    property color onErrorContainer: "#ffdad6"

    property color success: "#a6e3a1"
    property color onSuccess: "#101418"
    property color warning: "#f9e2af"
    property color onWarning: "#101418"
    property color info: "#99ccfa"

    property color inverseSurface: "#e0e2e8"
    property color inverseOnSurface: "#2d3135"
    property color inversePrimary: "#2c638b"

    property color scrim: "#000000"
    property color shadow: "#000000"

    readonly property var keys: ["background", "primary", "onPrimary", "primaryContainer", "onPrimaryContainer", "secondary", "onSecondary", "secondaryContainer", "onSecondaryContainer", "tertiary", "onTertiary", "tertiaryContainer", "onTertiaryContainer", "surface", "surfaceDim", "surfaceBright", "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "surfaceVariant", "onSurface", "onSurfaceVariant", "outline", "outlineVariant", "error", "onError", "errorContainer", "onErrorContainer", "success", "onSuccess", "warning", "onWarning", "info", "inverseSurface", "inverseOnSurface", "inversePrimary", "scrim", "shadow"]

    function loadColors(text: string): void {
        try {
            const d = JSON.parse(text);
            for (const k of root.keys) {
                if (d[k] !== undefined && d[k] !== null)
                    root[k] = d[k];
            }
            QsUtils.Logger.debug("Colours", "matugen-colors.json loaded");
        } catch (e) {
            QsUtils.Logger.error("Colours", "Failed to parse matugen-colors.json", e?.message ?? e);
        }
    }

    // matugen の atomic 書込で FileView 監視が外れるため、post_hook から明示リロードする。
    function reload(): void {
        matugenFile.reload();
    }

    FileView {
        id: matugenFile
        path: QsConfig.Config.paths.colours
        watchChanges: true
        onLoaded: root.loadColors(text())
        onFileChanged: root.loadColors(text())
        onLoadFailed: err => QsUtils.Logger.warn("Colours", `matugen-colors.json not loaded: ${FileViewError.toString(err)}`)
    }
}
