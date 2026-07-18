pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "utils" as QsUtils

// ~/.config/quickshell/shell.json を読む。環境に依存する値はここだけが持つ。
Singleton {
    id: root

    property var data: ({})

    readonly property string fontFamily: root.data.appearance?.fontFamily ?? "Inter"
    readonly property string iconFamily: root.data.appearance?.materialIconFont ?? "Material Design Icons"

    readonly property string coloursPath: root.expandHome(root.data.paths?.colours ?? "~/.cache/quickshell/matugen-colors.json")

    // waybar の下端（モニタ上端からの px）。バーの高さを変えたらここも変える。
    readonly property int barHeight: root.data.bar?.height ?? 40

    Component.onCompleted: file.reload()

    function expandHome(path) {
        if (!path || typeof path !== "string")
            return path;
        if (path.startsWith("~/"))
            return `${Quickshell.env("HOME")}/${path.slice(2)}`;
        return path;
    }

    FileView {
        id: file

        path: {
            const home = Quickshell.env("HOME");
            const xdg = Quickshell.env("XDG_CONFIG_HOME");
            const configHome = (xdg && xdg.length > 0) ? xdg : `${home}/.config`;
            return `${configHome}/quickshell/shell.json`;
        }
        watchChanges: true

        onLoaded: {
            try {
                root.data = JSON.parse(text());
                QsUtils.Logger.debug("Config", "shell.json loaded");
            } catch (e) {
                QsUtils.Logger.warn("Config", `Failed to parse shell.json: ${e?.message ?? e}`);
            }
        }

        onFileChanged: file.reload()

        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                QsUtils.Logger.warn("Config", `Failed to read shell.json: ${FileViewError.toString(err)}`);
        }
    }
}
