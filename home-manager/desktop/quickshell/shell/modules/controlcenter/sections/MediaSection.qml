import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../services" as QsServices
import "../../../config" as QsConfig

Item {
    id: root
    
    readonly property var players: QsServices.Players
    readonly property int pulseDuration: 1000
    readonly property int trackInfoSpacing: 1
    readonly property int breatheDuration: 1200
    readonly property int emptyIconSize: 56
    readonly property int artFallbackIconSize: 72

    // Selected player - automatically update when active player changes
    property var selectedPlayer: players.active
    
    // Watch for changes in active player and update selection
    Connections {
        target: players
        function onActiveChanged() {
            if (players.active && (!selectedPlayer || selectedPlayer !== players.active)) {
                selectedPlayer = players.active
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: QsConfig.Appearance.margin.l
        spacing: QsConfig.Appearance.spacing.s
        
        // Header with player selector
        RowLayout {
            Layout.fillWidth: true
            spacing: QsConfig.Appearance.spacing.m

            Text {
                text: "Media Player"
                font.family: QsConfig.Appearance.typography.family
                font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                font.weight: Font.Bold
                color: QsConfig.Theme.text
                Layout.fillWidth: true
            }
            
            // Player selector dropdown (only show if multiple players)
            Rectangle {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 160
                radius: QsConfig.Appearance.radius.s
                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.08)
                visible: players.list.length > 1
                z: 200  // Ensure dropdown appears above other content
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: QsConfig.Appearance.margin.s
                    spacing: QsConfig.Appearance.spacing.s
                    
                    Text {
                        text: "󰓃"
                        font.family: QsConfig.Appearance.typography.iconFamily
                        font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                        color: QsConfig.Theme.tertiary
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: selectedPlayer?.identity ?? "Select Player"
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                        color: QsConfig.Theme.text
                        elide: Text.ElideRight
                    }
                    
                    Text {
                        text: playerSelectorMenu.visible ? "󰅃" : "󰅀"
                        font.family: QsConfig.Appearance.typography.iconFamily
                        font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                        color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.6)
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: playerSelectorMenu.visible = !playerSelectorMenu.visible
                }
                
                // Dropdown menu
                Rectangle {
                    id: playerSelectorMenu
                    visible: false
                    anchors.top: parent.bottom
                    anchors.topMargin: QsConfig.Appearance.spacing.xs
                    anchors.left: parent.left
                    width: parent.width
                    height: Math.min(playerMenuColumn.implicitHeight + 8, 200)  // Max height to prevent overflow
                    radius: QsConfig.Appearance.radius.s
                    color: QsConfig.Theme.background
                    border.width: 1
                    border.color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.15)
                    z: 300  // Higher z-index for dropdown
                    
                    // Shadow effect
                    layer.enabled: true
                    layer.effect: Item {
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Qt.rgba(0, 0, 0, 0.2)
                            border.width: 1
                            radius: QsConfig.Appearance.radius.s
                        }
                    }
                    
                    ColumnLayout {
                        id: playerMenuColumn
                        anchors.fill: parent
                        anchors.margins: QsConfig.Appearance.spacing.xs
                        spacing: QsConfig.Appearance.spacing.xs
                        
                        Repeater {
                            model: players.list
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: QsConfig.Appearance.radius.xs
                                color: playerMouseArea.containsMouse ? 
                                       QsConfig.Theme.withAlpha(QsConfig.Theme.tertiary, 0.2) : 
                                       "transparent"
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: QsConfig.Appearance.margin.xs
                                    spacing: QsConfig.Appearance.spacing.s
                                    
                                    Text {
                                        text: modelData.isPlaying ? "󰐊" : "󰏤"
                                        font.family: QsConfig.Appearance.typography.iconFamily
                                        font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                                        color: modelData.isPlaying ? QsConfig.Theme.tertiary : QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.5)
                                    }
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.identity ?? "Unknown"
                                        font.family: QsConfig.Appearance.typography.family
                                        font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                                        color: QsConfig.Theme.text
                                        elide: Text.ElideRight
                                    }
                                    
                                    Text {
                                        text: "󰄬"
                                        font.family: QsConfig.Appearance.typography.iconFamily
                                        font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                                        color: QsConfig.Theme.tertiary
                                        visible: selectedPlayer === modelData
                                    }
                                }
                                
                                MouseArea {
                                    id: playerMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onClicked: {
                                        selectedPlayer = modelData
                                        playerSelectorMenu.visible = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Player content or no player message
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // No player active
            ColumnLayout {
                anchors.centerIn: parent
                spacing: QsConfig.Appearance.spacing.l
                visible: !selectedPlayer
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰝚"
                    font.family: QsConfig.Appearance.typography.iconFamily
                    font.pixelSize: root.emptyIconSize
                    color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.2)
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No media playing"
                    font.family: QsConfig.Appearance.typography.family
                    font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                    font.weight: Font.Medium
                    color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.5)
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Start playing media to control it here"
                    font.family: QsConfig.Appearance.typography.family
                    font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                    color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.35)
                }
            }
            
            // Active player
            ColumnLayout {
                anchors.fill: parent
                spacing: QsConfig.Appearance.spacing.s
                visible: selectedPlayer
                
                // Album art with glow effect
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220  // Reduced from 300px to fit all controls
                    
                    // Glow/shadow effect
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 20
                        height: parent.height - 20
                        radius: QsConfig.Appearance.radius.m
                        color: QsConfig.Theme.tertiary
                        opacity: selectedPlayer?.trackArtUrl ? 0.15 : 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: QsConfig.Appearance.anim.durations.medium; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    Rectangle {
                        id: albumArtRect
                        anchors.centerIn: parent
                        width: parent.width - 24
                        height: parent.height - 24
                        radius: QsConfig.Appearance.radius.m
                        color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                        clip: true
                        
                        scale: albumMouseArea.containsMouse ? 1.02 : 1.0
                        
                        Behavior on scale {
                            NumberAnimation { duration: QsConfig.Appearance.anim.durations.normal; easing.type: Easing.OutCubic }
                        }

                        Image {
                            id: albumArtImage
                            anchors.fill: parent
                            source: selectedPlayer?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            
                            opacity: status === Image.Ready ? 1 : 0
                            
                            Behavior on opacity {
                                NumberAnimation { duration: QsConfig.Appearance.anim.durations.medium; easing.type: Easing.OutCubic }
                            }
                        }
                        
                        // Fallback icon with animation
                        Text {
                            anchors.centerIn: parent
                            text: "󰝚"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: root.artFallbackIconSize
                            color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.15)
                            visible: albumArtImage.status !== Image.Ready
                            
                            SequentialAnimation on opacity {
                                running: visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.15; to: 0.3; duration: root.breatheDuration; easing.type: Easing.InOutCubic }
                                NumberAnimation { from: 0.3; to: 0.15; duration: root.breatheDuration; easing.type: Easing.InOutCubic }
                            }
                        }
                        
                        // Solid scrim for foreground legibility
                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0, 0, 0, 0.18)
                            visible: albumArtImage.status === Image.Ready
                        }
                        
                        // Playing indicator
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: QsConfig.Appearance.margin.m
                            width: 36
                            height: 36
                            radius: height / 2
                            color: selectedPlayer?.isPlaying ? QsConfig.Theme.tertiary : QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.3)
                            
                            Behavior on color {
                                ColorAnimation { duration: QsConfig.Appearance.anim.durations.normal }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: selectedPlayer?.isPlaying ? "󰐊" : "󰏤"
                                font.family: QsConfig.Appearance.typography.iconFamily
                                font.pixelSize: QsConfig.Appearance.typography.titleMedium.size
                                color: selectedPlayer?.isPlaying ? QsConfig.Theme.background : QsConfig.Theme.text
                            }
                        }
                        
                        MouseArea {
                            id: albumMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
                
                // Track info with better spacing
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: root.trackInfoSpacing
                    Layout.topMargin: QsConfig.Appearance.spacing.xs
                    
                    Text {
                        Layout.fillWidth: true
                        text: selectedPlayer?.trackTitle ?? "Unknown Track"
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                        font.weight: Font.Bold
                        color: QsConfig.Theme.text
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: selectedPlayer?.trackArtist ?? "Unknown Artist"
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                        color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.7)
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: selectedPlayer?.trackAlbum ?? ""
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                        color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.5)
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                    }
                }
                
                // Seek bar with improved design
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: QsConfig.Appearance.spacing.s

                    Slider {
                        id: seekSlider
                        Layout.fillWidth: true
                        from: 0
                        to: selectedPlayer?.length ?? 100
                        value: selectedPlayer?.position ?? 0
                        
                        onMoved: {
                            if (selectedPlayer) {
                                selectedPlayer.setPosition(value)
                            }
                        }
                        
                        background: Rectangle {
                            x: seekSlider.leftPadding
                            y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                            width: seekSlider.availableWidth
                            height: 6
                            radius: height / 2
                            color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
                            
                            Rectangle {
                                width: seekSlider.visualPosition * parent.width
                                height: parent.height
                                color: QsConfig.Theme.tertiary
                                radius: height / 2

                                Behavior on width {
                                    NumberAnimation { duration: QsConfig.Appearance.anim.durations.fast }
                                }
                            }
                        }
                        
                        handle: Rectangle {
                            x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                            y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                            width: 18
                            height: 18
                            radius: height / 2
                            color: QsConfig.Theme.background
                            border.color: QsConfig.Theme.tertiary
                            border.width: 2
                            
                            scale: seekSlider.pressed ? 1.2 : 1.0
                            
                            Behavior on scale {
                                NumberAnimation { duration: QsConfig.Appearance.anim.durations.fast }
                            }
                        }
                    }
                    
                    // Time labels
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: formatTime(selectedPlayer?.position ?? 0)
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                            font.weight: Font.Medium
                            color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.6)
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            text: formatTime(selectedPlayer?.length ?? 0)
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                            font.weight: Font.Medium
                            color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.6)
                        }
                    }
                }
                
                // Playback controls with animations
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: QsConfig.Appearance.spacing.xs
                    spacing: QsConfig.Appearance.spacing.m
                    
                    // Previous button
                    Rectangle {
                        width: 48
                        height: 48
                        radius: height / 2
                        color: prevHover.containsMouse ? 
                               QsConfig.Theme.withAlpha(QsConfig.Theme.error, 0.15) : 
                               QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                        
                        scale: prevHover.pressed ? 0.92 : 1.0
                        
                        Behavior on color {
                            ColorAnimation { duration: QsConfig.Appearance.anim.durations.fast }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: QsConfig.Appearance.anim.durations.fast; easing.type: Easing.OutCubic }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.headlineSmall.size
                            color: QsConfig.Theme.text
                        }
                        
                        MouseArea {
                            id: prevHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                if (selectedPlayer) {
                                    selectedPlayer.previous()
                                }
                            }
                        }
                    }
                    
                    // Play/Pause button (larger, prominent)
                    Rectangle {
                        width: 60
                        height: 60
                        radius: height / 2
                        color: QsConfig.Theme.tertiary
                        
                        scale: playHover.pressed ? 0.92 : (playHover.containsMouse ? 1.05 : 1.0)
                        
                        Behavior on scale {
                            NumberAnimation { duration: QsConfig.Appearance.anim.durations.fast; easing.type: Easing.OutBack }
                        }
                        
                        // Pulsing effect when playing
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: QsConfig.Theme.tertiary
                            opacity: 0
                            
                            SequentialAnimation on opacity {
                                running: selectedPlayer?.isPlaying ?? false
                                loops: Animation.Infinite
                                NumberAnimation { from: 0; to: 0.3; duration: root.pulseDuration; easing.type: Easing.OutCubic }
                                NumberAnimation { from: 0.3; to: 0; duration: root.pulseDuration; easing.type: Easing.InCubic }
                            }
                            
                            SequentialAnimation on scale {
                                running: selectedPlayer?.isPlaying ?? false
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 1.15; duration: root.pulseDuration; easing.type: Easing.OutCubic }
                                NumberAnimation { from: 1.15; to: 1.0; duration: root.pulseDuration; easing.type: Easing.InCubic }
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: (selectedPlayer?.isPlaying ?? false) ? "󰏤" : "󰐊"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.displaySmall.size
                            color: QsConfig.Theme.background
                        }
                        
                        MouseArea {
                            id: playHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                if (selectedPlayer) {
                                    selectedPlayer.togglePlaying()
                                }
                            }
                        }
                    }
                    
                    // Next button
                    Rectangle {
                        width: 48
                        height: 48
                        radius: height / 2
                        color: nextHover.containsMouse ? 
                               QsConfig.Theme.withAlpha(QsConfig.Theme.error, 0.15) : 
                               QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                        
                        scale: nextHover.pressed ? 0.92 : 1.0
                        
                        Behavior on color {
                            ColorAnimation { duration: QsConfig.Appearance.anim.durations.fast }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: QsConfig.Appearance.anim.durations.fast; easing.type: Easing.OutCubic }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.headlineSmall.size
                            color: QsConfig.Theme.text
                        }
                        
                        MouseArea {
                            id: nextHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                if (selectedPlayer) {
                                    selectedPlayer.next()
                                }
                            }
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }
        }
    }
    
    // Helper function to format time
    function formatTime(microseconds) {
        if (!microseconds || microseconds === 0 || microseconds < 0) {
            return "0:00"
        }
        const seconds = Math.floor(microseconds / 1000000)
        const mins = Math.floor(seconds / 60)
        const secs = seconds % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }
}
