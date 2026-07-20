pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick 6.10

// MPRIS プレイヤー。再生中のものを優先して選ぶ。
Singleton {
    id: root

    readonly property var players: Mpris.players.values

    // 再生中を優先し、無ければ先頭。
    readonly property var active: root.players.find(player => player.playbackState === MprisPlaybackState.Playing) ?? root.players[0] ?? null

    readonly property bool hasPlayer: root.active !== null
    readonly property bool playing: root.active?.playbackState === MprisPlaybackState.Playing

    readonly property string title: root.active?.trackTitle ?? ""
    readonly property string artist: root.active?.trackArtist ?? ""
    readonly property string artUrl: root.active?.trackArtUrl ?? ""

    function playPause(): void {
        root.active?.togglePlaying();
    }

    function next(): void {
        root.active?.next();
    }

    function previous(): void {
        root.active?.previous();
    }
}
