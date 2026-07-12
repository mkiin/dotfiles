pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils" as QsUtils

Singleton {
    id: root

    Component.onCompleted: file.reload()

    property var data: ({})

    function _expandHome(p) {
        if (!p || typeof p !== "string") return p
        if (p.startsWith("~/")) return `${Quickshell.env("HOME")}/${p.slice(2)}`
        return p
    }

    readonly property var appearance: ({
        fontFamily: data.appearance?.fontFamily ?? "Inter",
        materialIconFont: data.appearance?.materialIconFont ?? "Material Design Icons"
    })

    readonly property var paths: ({
        colours: _expandHome(data.paths?.colours ?? "~/.cache/quickshell/matugen-colors.json")
    })

    readonly property var notifications: ({
        popupWidth: data.notifications?.popupWidth ?? 340,
        maxVisible: data.notifications?.maxVisible ?? 5,
        timeoutMs: data.notifications?.timeoutMs ?? 7000,
        registerServer: data.notifications?.registerServer ?? true,
        spacing: data.notifications?.spacing ?? 8,
        margin: data.notifications?.margin ?? 8
    })

    FileView {
        id: file
        path: {
            const home = Quickshell.env("HOME")
            const xdg = Quickshell.env("XDG_CONFIG_HOME")
            const cfgHome = (xdg && xdg.length > 0) ? xdg : `${home}/.config`
            return `${cfgHome}/quickshell/shell.json`
        }
        watchChanges: true

        onLoaded: {
            try {
                const parsed = JSON.parse(text())
                root.data = parsed
                QsUtils.Logger.debug("Config", "shell.json loaded")
            } catch (e) {
                QsUtils.Logger.warn("Config", `Failed to parse shell.json: ${e?.message ?? e}`)
            }
        }

        onFileChanged: {
            file.reload()
        }

        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                QsUtils.Logger.warn("Config", `Failed to read shell.json: ${FileViewError.toString(err)}`)
        }
    }

}
