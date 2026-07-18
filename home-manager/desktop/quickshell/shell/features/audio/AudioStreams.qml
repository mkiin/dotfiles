pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    // 再生中アプリの出力ストリーム（sink input）のみを抽出
    readonly property var streams: (Pipewire.nodes && Pipewire.nodes.values)
        ? Pipewire.nodes.values.filter(n => n && n.isStream && n.isSink && n.audio)
        : []

    // アプリ単位に集約（Zen 等は音源ごとにストリームを増やすため、名前でまとめる）
    readonly property var groups: {
        const map = ({})
        const order = []
        for (const node of streams) {
            const key = appName(node)
            if (!map[key]) {
                map[key] = []
                order.push(key)
            }
            map[key].push(node)
        }
        return order.map(k => ({ name: k, nodes: map[k] }))
    }

    function appName(node) {
        if (!node)
            return ""
        const props = node.properties || ({})
        return props["application.name"] || props["media.name"] || node.name || ""
    }

    function setGroupVolume(nodes, vol) {
        for (const n of nodes) {
            if (n.audio) {
                n.audio.muted = false
                n.audio.volume = vol
            }
        }
    }

    function setGroupMuted(nodes, muted) {
        for (const n of nodes) {
            if (n.audio)
                n.audio.muted = muted
        }
    }
}
