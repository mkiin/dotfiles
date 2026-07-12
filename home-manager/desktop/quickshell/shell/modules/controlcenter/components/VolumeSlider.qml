import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../components/effects"
import "../../../services" as QsServices
import "../../../config" as QsConfig

Rectangle {
    id: root
    
    required property var audio
    readonly property int rowSpacing: 0

    // Current volume value - use PipeWire audio service
    readonly property int currentVolume: audio.percentage
    readonly property bool isMuted: audio.muted
    
    // Solid color tokens
    readonly property color surfaceColor: QsConfig.Theme.cardHigh
    readonly property color textColor: QsConfig.Theme.text
    readonly property color accentColor: QsConfig.Theme.accent
    
    Layout.fillWidth: true
    Layout.preferredHeight: 54
    
    radius: QsConfig.Appearance.radius.l
    color: surfaceColor
    border.width: 1
    border.color: QsConfig.Theme.border
    
    Behavior on color {
        ColorAnimation {
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.standard
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
            radius: QsConfig.Appearance.radius.l
            color: muteMouse.containsMouse 
                ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1) 
                : "transparent"
            
            Behavior on color {
                ColorAnimation {
                    duration: Material3Anim.short3
                    easing.bezierCurve: Material3Anim.standard
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: root.isMuted ? "󰝟" : (root.currentVolume > 66 ? "󰕾" : (root.currentVolume > 33 ? "󰖀" : "󰕿"))
                font.family: QsConfig.Appearance.typography.iconFamily
                font.pixelSize: QsConfig.Appearance.typography.titleLarge.size
                color: root.isMuted ? Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5) : root.accentColor
                
                Behavior on color {
                    ColorAnimation {
                        duration: Material3Anim.short3
                        easing.bezierCurve: Material3Anim.standard
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
            Layout.rightMargin: QsConfig.Appearance.margin.m

            value: root.currentVolume
            surfaceColor: root.surfaceColor

            onMoved: root.audio.setVolume(value / 100)
            onVolumeStepped: newValue => root.audio.setVolume(newValue / 100)
        }

        // Percentage Text
        Text {
            Layout.rightMargin: QsConfig.Appearance.margin.m
            Layout.preferredWidth: 44
            text: Math.round(slider.value) + "%"
            font.family: QsConfig.Appearance.typography.family
            font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
            font.weight: Font.DemiBold
            color: root.textColor
            horizontalAlignment: Text.AlignRight
        }
    }
}
