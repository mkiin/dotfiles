import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../theme" as QsTheme
import "../../../services" as QsServices

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
        anchors.margins: QsTheme.Appearance.margin.l
        spacing: QsTheme.Appearance.spacing.s
        
        // Header with player selector
        RowLayout {
            Layout.fillWidth: true
            spacing: QsTheme.Appearance.spacing.m

            Text {
                text: "Media Player"
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                font.weight: Font.Bold
                color: QsTheme.Theme.text
                Layout.fillWidth: true
            }
            
            // Player selector dropdown (only show if multiple players)
            Rectangle {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 160
                radius: QsTheme.Appearance.radius.s
                color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.08)
                visible: players.list.length > 1
                z: 200  // Ensure dropdown appears above other content
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: QsTheme.Appearance.margin.s
                    spacing: QsTheme.Appearance.spacing.s
                    
                    Text {
                        text: "󰓃"
                        font.family: QsTheme.Appearance.typography.iconFamily
                        font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                        color: QsTheme.Theme.tertiary
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: selectedPlayer?.identity ?? "Select Player"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                        color: QsTheme.Theme.text
                        elide: Text.ElideRight
                    }
                    
                    Text {
                        text: playerSelectorMenu.visible ? "󰅃" : "󰅀"
                        font.family: QsTheme.Appearance.typography.iconFamily
                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                        color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.6)
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
                    anchors.topMargin: QsTheme.Appearance.spacing.xs
                    anchors.left: parent.left
                    width: parent.width
                    height: Math.min(playerMenuColumn.implicitHeight + 8, 200)  // Max height to prevent overflow
                    radius: QsTheme.Appearance.radius.s
                    color: QsTheme.Theme.background
                    border.width: 1
                    border.color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.15)
                    z: 300  // Higher z-index for dropdown
                    
                    // Shadow effect
                    layer.enabled: true
                    layer.effect: Item {
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Qt.rgba(0, 0, 0, 0.2)
                            border.width: 1
                            radius: QsTheme.Appearance.radius.s
                        }
                    }
                    
                    ColumnLayout {
                        id: playerMenuColumn
                        anchors.fill: parent
                        anchors.margins: QsTheme.Appearance.spacing.xs
                        spacing: QsTheme.Appearance.spacing.xs
                        
                        Repeater {
                            model: players.list
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: QsTheme.Appearance.radius.xs
                                color: playerMouseArea.containsMouse ? 
                                       QsTheme.Theme.withAlpha(QsTheme.Theme.tertiary, 0.2) : 
                                       "transparent"
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: QsTheme.Appearance.margin.xs
                                    spacing: QsTheme.Appearance.spacing.s
                                    
                                    Text {
                                        text: modelData.isPlaying ? "󰐊" : "󰏤"
                                        font.family: QsTheme.Appearance.typography.iconFamily
                                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                                        color: modelData.isPlaying ? QsTheme.Theme.tertiary : QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.5)
                                    }
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.identity ?? "Unknown"
                                        font.family: QsTheme.Appearance.typography.family
                                        font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                                        color: QsTheme.Theme.text
                                        elide: Text.ElideRight
                                    }
                                    
                                    Text {
                                        text: "󰄬"
                                        font.family: QsTheme.Appearance.typography.iconFamily
                                        font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                                        color: QsTheme.Theme.tertiary
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
                spacing: QsTheme.Appearance.spacing.l
                visible: !selectedPlayer
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰝚"
                    font.family: QsTheme.Appearance.typography.iconFamily
                    font.pixelSize: root.emptyIconSize
                    color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.2)
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No media playing"
                    font.family: QsTheme.Appearance.typography.family
                    font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                    font.weight: Font.Medium
                    color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.5)
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Start playing media to control it here"
                    font.family: QsTheme.Appearance.typography.family
                    font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                    color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.35)
                }
            }
            
            // Active player
            ColumnLayout {
                anchors.fill: parent
                spacing: QsTheme.Appearance.spacing.s
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
                        radius: QsTheme.Appearance.radius.m
                        color: QsTheme.Theme.tertiary
                        opacity: selectedPlayer?.trackArtUrl ? 0.15 : 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: QsTheme.Appearance.anim.durations.medium; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    Rectangle {
                        id: albumArtRect
                        anchors.centerIn: parent
                        width: parent.width - 24
                        height: parent.height - 24
                        radius: QsTheme.Appearance.radius.m
                        color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.05)
                        clip: true
                        
                        scale: albumMouseArea.containsMouse ? 1.02 : 1.0
                        
                        Behavior on scale {
                            NumberAnimation { duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.OutCubic }
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
                                NumberAnimation { duration: QsTheme.Appearance.anim.durations.medium; easing.type: Easing.OutCubic }
                            }
                        }
                        
                        // Fallback icon with animation
                        Text {
                            anchors.centerIn: parent
                            text: "󰝚"
                            font.family: QsTheme.Appearance.typography.iconFamily
                            font.pixelSize: root.artFallbackIconSize
                            color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.15)
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
                            anchors.margins: QsTheme.Appearance.margin.m
                            width: 36
                            height: 36
                            radius: height / 2
                            color: selectedPlayer?.isPlaying ? QsTheme.Theme.tertiary : QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.3)
                            
                            Behavior on color {
                                ColorAnimation { duration: QsTheme.Appearance.anim.durations.normal }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: selectedPlayer?.isPlaying ? "󰐊" : "󰏤"
                                font.family: QsTheme.Appearance.typography.iconFamily
                                font.pixelSize: QsTheme.Appearance.typography.titleMedium.size
                                color: selectedPlayer?.isPlaying ? QsTheme.Theme.background : QsTheme.Theme.text
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
                    Layout.topMargin: QsTheme.Appearance.spacing.xs
                    
                    Text {
                        Layout.fillWidth: true
                        text: selectedPlayer?.trackTitle ?? "Unknown Track"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                        font.weight: Font.Bold
                        color: QsTheme.Theme.text
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: selectedPlayer?.trackArtist ?? "Unknown Artist"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                        color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.7)
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: selectedPlayer?.trackAlbum ?? ""
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                        color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.5)
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                    }
                }
                
                // Seek bar with improved design
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: QsTheme.Appearance.spacing.s

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
                            color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.1)
                            
                            Rectangle {
                                width: seekSlider.visualPosition * parent.width
                                height: parent.height
                                color: QsTheme.Theme.tertiary
                                radius: height / 2

                                Behavior on width {
                                    NumberAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                                }
                            }
                        }
                        
                        handle: Rectangle {
                            x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                            y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                            width: 18
                            height: 18
                            radius: height / 2
                            color: QsTheme.Theme.background
                            border.color: QsTheme.Theme.tertiary
                            border.width: 2
                            
                            scale: seekSlider.pressed ? 1.2 : 1.0
                            
                            Behavior on scale {
                                NumberAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                            }
                        }
                    }
                    
                    // Time labels
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: formatTime(selectedPlayer?.position ?? 0)
                            font.family: QsTheme.Appearance.typography.family
                            font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                            font.weight: Font.Medium
                            color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.6)
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            text: formatTime(selectedPlayer?.length ?? 0)
                            font.family: QsTheme.Appearance.typography.family
                            font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                            font.weight: Font.Medium
                            color: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.6)
                        }
                    }
                }
                
                // Playback controls with animations
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: QsTheme.Appearance.spacing.xs
                    spacing: QsTheme.Appearance.spacing.m
                    
                    // Previous button
                    Rectangle {
                        width: 48
                        height: 48
                        radius: height / 2
                        color: prevHover.containsMouse ? 
                               QsTheme.Theme.withAlpha(QsTheme.Theme.error, 0.15) : 
                               QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.05)
                        
                        scale: prevHover.pressed ? 0.92 : 1.0
                        
                        Behavior on color {
                            ColorAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: QsTheme.Appearance.anim.durations.fast; easing.type: Easing.OutCubic }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: QsTheme.Appearance.typography.iconFamily
                            font.pixelSize: QsTheme.Appearance.typography.headlineSmall.size
                            color: QsTheme.Theme.text
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
                        color: QsTheme.Theme.tertiary
                        
                        scale: playHover.pressed ? 0.92 : (playHover.containsMouse ? 1.05 : 1.0)
                        
                        Behavior on scale {
                            NumberAnimation { duration: QsTheme.Appearance.anim.durations.fast; easing.type: Easing.OutBack }
                        }
                        
                        // Pulsing effect when playing
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: QsTheme.Theme.tertiary
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
                            font.family: QsTheme.Appearance.typography.iconFamily
                            font.pixelSize: QsTheme.Appearance.typography.displaySmall.size
                            color: QsTheme.Theme.background
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
                               QsTheme.Theme.withAlpha(QsTheme.Theme.error, 0.15) : 
                               QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.05)
                        
                        scale: nextHover.pressed ? 0.92 : 1.0
                        
                        Behavior on color {
                            ColorAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: QsTheme.Appearance.anim.durations.fast; easing.type: Easing.OutCubic }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: QsTheme.Appearance.typography.iconFamily
                            font.pixelSize: QsTheme.Appearance.typography.headlineSmall.size
                            color: QsTheme.Theme.text
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
