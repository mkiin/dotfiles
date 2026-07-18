pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// 既定の出力/入力デバイスの音量。
// Pipewire のノードに直接バインドする（wpctl を 250ms ごとに叩く実装から置き換えた）。
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool ready: root.sink?.ready ?? false
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property int percentage: Math.round(root.volume * 100)

    readonly property bool sourceReady: root.source?.ready ?? false
    readonly property bool sourceMuted: root.source?.audio?.muted ?? false
    readonly property real sourceVolume: root.source?.audio?.volume ?? 0
    readonly property int sourcePercentage: Math.round(root.sourceVolume * 100)

    // tracker で保持しないと audio プロパティの変更通知が来ない
    PwObjectTracker {
        objects: [root.sink, root.source].filter(node => node)
    }

    function clamp(value) {
        return Math.max(0, Math.min(1.5, value));
    }

    function setVolume(value) {
        if (!root.sink?.audio)
            return;
        root.sink.audio.muted = false;
        root.sink.audio.volume = root.clamp(value);
    }

    function increaseVolume() {
        root.setVolume(root.volume + 0.05);
    }

    function decreaseVolume() {
        root.setVolume(root.volume - 0.05);
    }

    function setMute(muted) {
        if (root.sink?.audio)
            root.sink.audio.muted = muted;
    }

    function toggleMute() {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    function setSourceVolume(value) {
        if (!root.source?.audio)
            return;
        root.source.audio.muted = false;
        root.source.audio.volume = root.clamp(value);
    }

    function setSourceMute(muted) {
        if (root.source?.audio)
            root.source.audio.muted = muted;
    }

    function toggleSourceMute() {
        if (root.source?.audio)
            root.source.audio.muted = !root.source.audio.muted;
    }
}
