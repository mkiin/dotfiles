pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// アプリ起動の頻度×新しさ(frecency)を永続化し、ランチャーの並びに使う
Singleton {
    id: root

    readonly property var apps: usageData.apps

    function record(id) {
        if (!id)
            return
        const map = Object.assign({}, usageData.apps)
        const prev = map[id] ?? ({ count: 0, last: 0 })
        map[id] = { count: (prev.count ?? 0) + 1, last: Date.now() }
        usageData.apps = map
        usageFile.writeAdapter()
    }

    function score(id) {
        const e = usageData.apps[id]
        if (!e || !e.count)
            return 0
        const ageDays = Math.max(0, (Date.now() - (e.last ?? 0)) / 86400000)
        const recency = 1 / (1 + ageDays)
        return e.count * (0.3 + 0.7 * recency)
    }

    FileView {
        id: usageFile
        path: `${Quickshell.env("HOME")}/.cache/quickshell/launcher-usage.json`
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: usageData
            property var apps: ({})
        }
    }
}
