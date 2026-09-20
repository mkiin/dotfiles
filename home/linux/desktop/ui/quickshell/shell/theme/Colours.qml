pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10
import ".." as QsRoot
import "../utils" as QsUtils

// matugen が書き出す M3 トークンをそのまま保持する層。ここでは色を加工しない。
// 意味づけは Theme が行う。
//
// 読み込んだ JSON は data にまとめて持ち、各トークンは readonly で公開する。
// on* を書込可プロパティにすると QML がシグナルハンドラと解釈するため、この形にしている。
// data の既定値は matugen 未生成時の初回起動用フォールバック。
Singleton {
    id: root

    property var data: ({
            background: "#101418",

            primary: "#99ccfa",
            onPrimary: "#003353",
            primaryContainer: "#084b72",
            onPrimaryContainer: "#cde5ff",

            secondary: "#b8c8da",
            onSecondary: "#233240",
            secondaryContainer: "#394857",
            onSecondaryContainer: "#d4e4f6",

            tertiary: "#d2bfe7",
            onTertiary: "#372b4a",
            tertiaryContainer: "#4e4161",
            onTertiaryContainer: "#eddcff",

            surface: "#101418",
            surfaceDim: "#101418",
            surfaceBright: "#36393e",
            surfaceContainerLowest: "#0b0f12",
            surfaceContainerLow: "#181c20",
            surfaceContainer: "#1c2024",
            surfaceContainerHigh: "#272a2e",
            surfaceContainerHighest: "#313539",
            surfaceVariant: "#42474e",

            onSurface: "#e0e2e8",
            onSurfaceVariant: "#c2c7ce",

            outline: "#8c9198",
            outlineVariant: "#42474e",

            error: "#ffb4ab",
            onError: "#690005",
            errorContainer: "#93000a",
            onErrorContainer: "#ffdad6",

            success: "#a6e3a1",
            onSuccess: "#0d1b0c",
            warning: "#f9e2af",
            onWarning: "#241d04",
            info: "#99ccfa",

            inverseSurface: "#e0e2e8",
            inverseOnSurface: "#2d3135",
            inversePrimary: "#2c638b",

            scrim: "#000000",
            shadow: "#000000"
        })

    readonly property color background: root.data.background

    readonly property color primary: root.data.primary
    readonly property color _onPrimary: root.data.onPrimary
    readonly property color primaryContainer: root.data.primaryContainer
    readonly property color _onPrimaryContainer: root.data.onPrimaryContainer

    readonly property color secondary: root.data.secondary
    readonly property color _onSecondary: root.data.onSecondary
    readonly property color secondaryContainer: root.data.secondaryContainer
    readonly property color _onSecondaryContainer: root.data.onSecondaryContainer

    readonly property color tertiary: root.data.tertiary
    readonly property color _onTertiary: root.data.onTertiary
    readonly property color tertiaryContainer: root.data.tertiaryContainer
    readonly property color _onTertiaryContainer: root.data.onTertiaryContainer

    readonly property color surface: root.data.surface
    readonly property color surfaceDim: root.data.surfaceDim
    readonly property color surfaceBright: root.data.surfaceBright
    readonly property color surfaceContainerLowest: root.data.surfaceContainerLowest
    readonly property color surfaceContainerLow: root.data.surfaceContainerLow
    readonly property color surfaceContainer: root.data.surfaceContainer
    readonly property color surfaceContainerHigh: root.data.surfaceContainerHigh
    readonly property color surfaceContainerHighest: root.data.surfaceContainerHighest
    readonly property color surfaceVariant: root.data.surfaceVariant

    readonly property color _onSurface: root.data.onSurface
    readonly property color _onSurfaceVariant: root.data.onSurfaceVariant

    readonly property color outline: root.data.outline
    readonly property color outlineVariant: root.data.outlineVariant

    readonly property color error: root.data.error
    readonly property color _onError: root.data.onError
    readonly property color errorContainer: root.data.errorContainer
    readonly property color _onErrorContainer: root.data.onErrorContainer

    readonly property color success: root.data.success
    readonly property color _onSuccess: root.data.onSuccess
    readonly property color warning: root.data.warning
    readonly property color _onWarning: root.data.onWarning
    readonly property color info: root.data.info

    readonly property color inverseSurface: root.data.inverseSurface
    readonly property color inverseOnSurface: root.data.inverseOnSurface
    readonly property color inversePrimary: root.data.inversePrimary

    readonly property color scrim: root.data.scrim
    readonly property color shadow: root.data.shadow

    function loadColors(text: string): void {
        try {
            root.data = Object.assign({}, root.data, JSON.parse(text));
            QsUtils.Logger.debug("Colours", "matugen-colors.json loaded");
        } catch (e) {
            QsUtils.Logger.error("Colours", "Failed to parse matugen-colors.json", e?.message ?? e);
        }
    }

    // FileView は参照されるまで読み込みを始めないため、起動時に明示的に読む。
    Component.onCompleted: matugenFile.reload()

    // matugen の atomic 書込で FileView 監視が外れるため、post_hook からも明示リロードする。
    function reload(): void {
        matugenFile.reload();
    }

    FileView {
        id: matugenFile
        path: QsRoot.Config.coloursPath
        watchChanges: true
        onLoaded: root.loadColors(text())
        onFileChanged: root.loadColors(text())
        onLoadFailed: err => QsUtils.Logger.warn("Colours", `matugen-colors.json not loaded: ${FileViewError.toString(err)}`)
    }
}
