import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../ui"
import "../../../theme" as QsTheme

Rectangle {
    id: root
    
    required property var audio
    readonly property int rowSpacing: 0

    // Current volume value - use PipeWire audio service
    readonly property int currentVolume: audio.percentage
    readonly property bool isMuted: audio.muted
    
    // Solid color tokens
    readonly property color surfaceColor: QsTheme.Theme.cardHigh
    readonly property color textColor: QsTheme.Theme.text
    readonly property color accentColor: QsTheme.Theme.accent
    
    Layout.fillWidth: true
    Layout.preferredHeight: 54
    
    radius: QsTheme.Appearance.radius.l
    color: surfaceColor
    border.width: 1
    border.color: QsTheme.Theme.border
    
    Behavior on color {
        ColorAnimation {
            duration: QsTheme.Appearance.anim.durations.medium2
            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: root.rowSpacing
        
        // Mute Button
        Rectangle {
            id: muteBtn
            Layout.preferredWidth: 52
            Layout.fillHeight: true
            radius: QsTheme.Appearance.radius.l
            color: muteMouse.containsMouse 
                ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1) 
                : "transparent"
            
            Behavior on color {
                ColorAnimation {
                    duration: QsTheme.Appearance.anim.durations.short3
                    easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: root.isMuted ? "󰝟" : (root.currentVolume > 66 ? "󰕾" : (root.currentVolume > 33 ? "󰖀" : "󰕿"))
                font.family: QsTheme.Appearance.typography.iconFamily
                font.pixelSize: QsTheme.Appearance.typography.titleLarge.size
                color: root.isMuted ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5) : root.accentColor
                
                Behavior on color {
                    ColorAnimation {
                        duration: QsTheme.Appearance.anim.durations.short3
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }
            }
            
            MouseArea {
                id: muteMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.audio.toggleMute()
            }
        }
        
        // Slider
        VolumeTrack {
            id: slider
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: QsTheme.Appearance.margin.m

            value: root.currentVolume
            surfaceColor: root.surfaceColor

            onMoved: root.audio.setVolume(value / 100)
            onVolumeStepped: newValue => root.audio.setVolume(newValue / 100)
        }

        // Percentage Text
        Text {
            Layout.rightMargin: QsTheme.Appearance.margin.m
            Layout.preferredWidth: 44
            text: Math.round(slider.value) + "%"
            font.family: QsTheme.Appearance.typography.family
            font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
            font.weight: Font.DemiBold
            color: root.textColor
            horizontalAlignment: Text.AlignRight
        }
    }
}
