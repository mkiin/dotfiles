import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import QtQuick.Effects
import Quickshell
import "../../../theme" as QsTheme

Rectangle {
    id: root
    
    required property var mpris
    
    // Get active player safely
    readonly property var activePlayer: mpris?.active ?? null
    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && (activePlayer.isPlaying ?? false)
    readonly property string trackTitle: hasPlayer ? (activePlayer.trackTitle ?? "Unknown") : ""
    readonly property string trackArtist: hasPlayer ? (activePlayer.trackArtist ?? "") : ""
    
    // Store art URL separately to prevent flickering - only update when we have a valid new URL
    property string artUrl: ""
    
    onActivePlayerChanged: {
        // Drop the previous player's art immediately so a stale thumbnail can't
        // linger if the new player's URL arrives a beat later.
        artUrl = ""
        updateArtUrl()
    }

    // Connection to MPRIS service for when active player changes
    Connections {
        target: mpris
        function onActiveChanged() {
            root.updateArtUrl()
        }
    }

    Connections {
        target: activePlayer
        function onTrackArtUrlChanged() {
            root.updateArtUrl()
        }
        function onTrackTitleChanged() {
            root.updateArtUrl()
        }
        function onPlaybackStateChanged() {
            root.updateArtUrl()
        }
    }

    function updateArtUrl() {
        if (activePlayer && activePlayer.trackArtUrl && activePlayer.trackArtUrl !== "") {
            artUrl = activePlayer.trackArtUrl
        }
    }
    
    radius: QsTheme.Appearance.radius.m
    color: QsTheme.Theme.card
    clip: true
    visible: hasPlayer
    
    
    // Blurred album art background
    Image {
        id: bgImage
        anchors.fill: parent
        anchors.margins: -20
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }
    
    MultiEffect {
        anchors.fill: parent
        source: bgImage
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: 0.4
        brightness: -0.35
        opacity: bgImage.status === Image.Ready ? 1 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: QsTheme.Appearance.anim.durations.medium4
                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
            }
        }
    }
    
    // Dark overlay for readability
    Rectangle {
        anchors.fill: parent
        color: QsTheme.Theme.scrim
        visible: bgImage.status === Image.Ready
    }
    
    // Initial load timer - poll for artwork until found
    Timer {
        id: artworkPoller
        interval: 200
        repeat: true
        running: root.hasPlayer && root.artUrl === ""
        property int attempts: 0
        onTriggered: {
            root.updateArtUrl()
            attempts++
            if (attempts > 25 || root.artUrl !== "") {
                running = false
                attempts = 0
            }
        }
    }
    
    // Delayed initialization to ensure MPRIS data is ready
    Timer {
        id: initTimer
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            root.updateArtUrl()
            // Start artwork poller if still no art
            if (root.hasPlayer && root.artUrl === "") {
                artworkPoller.running = true
            }
        }
    }
    
    Component.onCompleted: {
        // Immediate attempt
        updateArtUrl()
    }
    
    // Content
    RowLayout {
        anchors.fill: parent
        anchors.margins: QsTheme.Appearance.margin.m
        spacing: QsTheme.Appearance.spacing.l
        
        // Album Art
        Rectangle {
            Layout.preferredWidth: 72
            Layout.preferredHeight: 72
            radius: QsTheme.Appearance.radius.s
            color: QsTheme.Theme.cardHigh
            clip: true
            
            // Shadow
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: QsTheme.Theme.shadow
            shadowOpacity: 0.4
                shadowBlur: 0.3
                shadowVerticalOffset: 2
            }
            
            Image {
                id: albumArt
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                
                opacity: status === Image.Ready ? 1 : 0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: QsTheme.Appearance.anim.durations.short4
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }
            }
            
            // Placeholder
            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: QsTheme.Appearance.typography.iconFamily
                font.pixelSize: QsTheme.Appearance.typography.headlineLarge.size
                color: QsTheme.Theme.textVariant
                visible: albumArt.status !== Image.Ready
            }
        }
        
        // Track Info
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: QsTheme.Appearance.spacing.xs
            
            Item { Layout.fillHeight: true }
            
            Text {
                Layout.fillWidth: true
                text: root.trackTitle || "No Media"
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                font.weight: Font.Bold
                color: QsTheme.Theme.text
                elide: Text.ElideRight
                maximumLineCount: 1
                
                // Text shadow for readability
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: QsTheme.Theme.shadow
            shadowOpacity: 0.5
                    shadowBlur: 0.2
                }
            }
            
            Text {
                Layout.fillWidth: true
                text: root.trackArtist
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                color: QsTheme.Theme.textVariant
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text !== ""
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: QsTheme.Theme.shadow
            shadowOpacity: 0.5
                    shadowBlur: 0.2
                }
            }
            
            Item { Layout.fillHeight: true }
        }
        
        // Controls
        RowLayout {
            spacing: QsTheme.Appearance.spacing.xs
            
            // Previous
            ControlButton {
                icon: "󰒮"
                onClicked: {
                    if (root.activePlayer) root.activePlayer.previous()
                }
            }
            
            // Play/Pause - Main button
            Rectangle {
                id: playBtn
                width: 48
                height: 48
                radius: height / 2
                color: QsTheme.Theme.primary
                
                scale: playMouse.pressed ? 0.92 : (playMouse.containsMouse ? 1.05 : 1.0)
                
                Behavior on scale {
                    NumberAnimation {
                        duration: QsTheme.Appearance.anim.durations.short2
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }
                
                // Glow effect
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: QsTheme.Theme.primary
                    shadowBlur: 0.4
                    shadowOpacity: 0.5
                }
                
                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    font.family: QsTheme.Appearance.typography.iconFamily
                    font.pixelSize: QsTheme.Appearance.typography.headlineSmall.size
                    color: QsTheme.Theme.background
                }
                
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (root.activePlayer) root.activePlayer.togglePlaying()
                    }
                }
            }
            
            // Next
            ControlButton {
                icon: "󰒭"
                onClicked: {
                    if (root.activePlayer) root.activePlayer.next()
                }
            }
        }
    }
    
    component ControlButton: Rectangle {
        property string icon
        signal clicked()
        
        width: 40
        height: 40
        radius: height / 2
        color: btnMouse.containsMouse 
            ? QsTheme.Theme.cardHigh 
            : QsTheme.Theme.card
        
        scale: btnMouse.pressed ? 0.9 : 1.0
        
        
        Behavior on scale {
            NumberAnimation {
                duration: QsTheme.Appearance.anim.durations.short2
                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
            }
        }
        
        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: QsTheme.Appearance.typography.iconFamily
            font.pixelSize: QsTheme.Appearance.typography.titleLarge.size
            color: QsTheme.Theme.text
        }
        
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }
}
