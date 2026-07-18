pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick 6.10

Singleton {
    id: root

    readonly property var list: Mpris.players.values
    
    // Consumer visibility control - set to false to pause polling when UI is hidden
    property bool visible: true
    
    // Currently playing player, falling back to first available if none playing.
    property var active: null

    Component.onCompleted: root.updateActivePlayer()

    // React to MPRIS player changes via Connections (event-driven)
    Connections {
        target: Mpris.players

        function onValuesChanged() {
            root.updateActivePlayer()
        }
    }

    // Re-select whenever any player's playback state flips, so `active` tracks
    // the player that is actually Playing rather than whoever was first.
    Instantiator {
        model: root.list
        delegate: Connections {
            required property var modelData
            target: modelData
            function onPlaybackStateChanged() { root.updateActivePlayer() }
        }
    }

    function updateActivePlayer() {
        var newActive = null
        // Prefer a player that is actively Playing.
        for (var i = 0; i < list.length; i++) {
            if (list[i]?.playbackState === MprisPlaybackState.Playing) {
                newActive = list[i]
                break
            }
        }
        // If none is playing, fall back to the first available player.
        if (!newActive && list.length > 0) {
            newActive = list[0]
        }
        if (active !== newActive) {
            active = newActive
        }
    }

    // Fallback timer for edge cases (only runs when visible)
    Timer {
        interval: 2000  // Increased from 1000ms since we have event-driven updates
        running: root.visible && list.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateActivePlayer()
    }

    function getIdentity(player: var): string {
        return player?.identity ?? "Unknown";
    }
}
