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
    property color _onPrimary: "#003353"
    readonly property color onPrimary: root._onPrimary
    property color primaryContainer: "#084b72"
    property color _onPrimaryContainer: "#cde5ff"
    readonly property color onPrimaryContainer: root._onPrimaryContainer

    property color secondary: "#b8c8da"
    property color _onSecondary: "#233240"
    readonly property color onSecondary: root._onSecondary
    property color secondaryContainer: "#394857"
    property color _onSecondaryContainer: "#d4e4f6"
    readonly property color onSecondaryContainer: root._onSecondaryContainer

    property color tertiary: "#d2bfe7"
    property color _onTertiary: "#372b4a"
    readonly property color onTertiary: root._onTertiary
    property color tertiaryContainer: "#4e4161"
    property color _onTertiaryContainer: "#eddcff"
    readonly property color onTertiaryContainer: root._onTertiaryContainer

    property color surface: "#101418"
    property color surfaceDim: "#101418"
    property color surfaceBright: "#36393e"
    property color surfaceContainerLowest: "#0b0f12"
    property color surfaceContainerLow: "#181c20"
    property color surfaceContainer: "#1c2024"
    property color surfaceContainerHigh: "#272a2e"
    property color surfaceContainerHighest: "#313539"
    property color surfaceVariant: "#42474e"

    property color _onSurface: "#e0e2e8"
    readonly property color onSurface: root._onSurface
    property color _onSurfaceVariant: "#c2c7ce"
    readonly property color onSurfaceVariant: root._onSurfaceVariant

    property color outline: "#8c9198"
    property color outlineVariant: "#42474e"

    property color error: "#ffb4ab"
    property color _onError: "#690005"
    readonly property color onError: root._onError
    property color errorContainer: "#93000a"
    property color _onErrorContainer: "#ffdad6"
    readonly property color onErrorContainer: root._onErrorContainer

    property color success: "#a6e3a1"
    property color _onSuccess: "#101418"
    readonly property color onSuccess: root._onSuccess
    property color warning: "#f9e2af"
    property color _onWarning: "#101418"
    readonly property color onWarning: root._onWarning
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
            // on* は書込可プロパティにすると QML のシグナルハンドラ文法と衝突するため、
            // 内部名 _on* に入れて readonly で公開している。
            for (const k of root.keys) {
                if (d[k] === undefined || d[k] === null)
                    continue;
                root[k.startsWith("on") ? "_" + k : k] = d[k];
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
