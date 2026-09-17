pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// オーディオの状態と操作。値は Pipewire が持つので、ここでは参照と導出だけを行う。
Singleton {
    id: root

    // ── 既定デバイス ──
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property int percentage: Math.round(root.volume * 100)

    readonly property bool sourceMuted: root.source?.audio?.muted ?? false
    readonly property real sourceVolume: root.source?.audio?.volume ?? 0
    readonly property int sourcePercentage: Math.round(root.sourceVolume * 100)

    // ── デバイス一覧（アプリのストリームは除く） ──
    readonly property var sinks: Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(node => node.audio && !node.isSink && !node.isStream)

    // ── アプリのストリーム ──
    // application.name でまとめない。同じアプリでも音源ごとに別々に扱う。
    readonly property var streams: Pipewire.nodes.values.filter(node => node.audio && node.isSink && node.isStream)

    // Pipewire は誰かがノードを保持するまで接続しない。
    // 絞り込んだ結果を渡すと接続前は空になり、いつまでも繋がらないので全ノードを渡す。
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    // ── 音量 ──
    function clamp(value: real): real {
        return Math.max(0, Math.min(1.5, value));
    }

    function setVolume(value: real): void {
        if (!root.sink?.audio)
            return;
        root.sink.audio.muted = false;
        root.sink.audio.volume = root.clamp(value);
    }

    function toggleMute(): void {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    function setSourceVolume(value: real): void {
        if (!root.source?.audio)
            return;
        root.source.audio.muted = false;
        root.source.audio.volume = root.clamp(value);
    }

    function toggleSourceMute(): void {
        if (root.source?.audio)
            root.source.audio.muted = !root.source.audio.muted;
    }

    // ── ストリームごとの音量 ──
    function setStreamVolume(node, value: real): void {
        if (!node?.audio)
            return;
        node.audio.muted = false;
        node.audio.volume = root.clamp(value);
    }

    function toggleStreamMute(node): void {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    // ── 既定デバイスの切り替え ──
    function setDefaultSink(node): void {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node): void {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    // ── 表示用の導出 ──
    // Pipewire はデバイスの種類を持たないので、名前から推測する。
    function iconFor(node): string {
        const label = ((node?.description ?? "") + " " + (node?.name ?? "")).toLowerCase();
        if (label.includes("headphone") || label.includes("headset"))
            return "󰋋";
        if (label.includes("hdmi") || label.includes("displayport") || label.includes("display"))
            return "󰍹";
        if (label.includes("bluetooth") || label.includes("bluez"))
            return "󰂰";
        return "󰓃";
    }

    function labelFor(node): string {
        return node?.description || node?.name || "";
    }

    // ストリームは音源名を主に出す。同じアプリの別タブを区別するため。
    function streamLabel(node): string {
        const props = node?.properties ?? ({});
        return props["media.name"] || props["application.name"] || node?.name || "";
    }

    function streamApp(node): string {
        return node?.properties?.["application.name"] ?? "";
    }
}
