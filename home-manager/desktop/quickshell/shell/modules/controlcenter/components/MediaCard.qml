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
    
    // Color tokens
    readonly property color surfaceColor: QsTheme.Theme.card
    readonly property color textColor: QsTheme.Theme.text
    readonly property color textDim: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.7)
    readonly property color accentColor: QsTheme.Theme.accent
    
    Layout.fillWidth: true
    Layout.preferredHeight: hasPlayer ? 100 : 0
    
    radius: QsTheme.Appearance.radius.m
    color: surfaceColor
    clip: true
    visible: hasPlayer
    
    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: QsTheme.Appearance.anim.durations.medium2
            easing.bezierCurve: QsTheme.Appearance.anim.curves.emphasizedDecel
        }
    }
    
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
        color: QsTheme.Theme.withAlpha(QsTheme.Theme.background, 0.4)
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
            color: Qt.rgba(1, 1, 1, 0.1)
            clip: true
            
            // Shadow
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.4)
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
                color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.3)
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
                color: root.textColor
                elide: Text.ElideRight
                maximumLineCount: 1
                
                // Text shadow for readability
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.5)
                    shadowBlur: 0.2
                }
            }
            
            Text {
                Layout.fillWidth: true
                text: root.trackArtist
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                color: root.textDim
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text !== ""
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.5)
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
                color: root.accentColor
                
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
                    shadowColor: root.accentColor
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
            ? Qt.rgba(1, 1, 1, 0.15) 
            : Qt.rgba(1, 1, 1, 0.05)
        
        scale: btnMouse.pressed ? 0.9 : 1.0
        
        Behavior on color {
            ColorAnimation {
                duration: QsTheme.Appearance.anim.durations.short3
                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
            }
        }
        
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
            color: root.textColor
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
