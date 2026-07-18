import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../theme" as QsTheme

Rectangle {
    id: root
    
    required property var brightness
    readonly property int rowSpacing: 0

    // Current brightness value
    readonly property int currentBrightness: brightness ? Math.round((brightness.percentage ?? 0)) : 0
    
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
        
        // Icon
        Rectangle {
            id: iconBtn
            Layout.preferredWidth: 52
            Layout.fillHeight: true
            radius: QsTheme.Appearance.radius.l
            color: iconMouse.containsMouse 
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
                text: root.currentBrightness > 70 ? "󰃠" : (root.currentBrightness > 30 ? "󰃟" : "󰃞")
                font.family: QsTheme.Appearance.typography.iconFamily
                font.pixelSize: QsTheme.Appearance.typography.titleLarge.size
                color: root.accentColor
            }
            
            MouseArea {
                id: iconMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }
        
        // Slider
        Slider {
            id: slider
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: QsTheme.Appearance.margin.m

            from: 0
            to: 100
            value: root.currentBrightness
            live: true

            onMoved: root.brightness.setBrightness(value / 100)

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 30
                width: slider.availableWidth
                height: implicitHeight
                radius: height / 2
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.08)

                // Progress fill
                Rectangle {
                    width: slider.position * parent.width
                    height: parent.height
                    radius: height / 2
                    color: root.accentColor
                    opacity: 0.34

                    Behavior on width {
                        NumberAnimation {
                            duration: QsTheme.Appearance.anim.durations.short2
                            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                        }
                    }
                }

                Rectangle {
                    width: 10
                    height: 10
                    radius: height / 2
                    x: Math.max(0, Math.min(parent.width - width, slider.position * parent.width - width / 2))
                    y: (parent.height - height) / 2
                    color: root.accentColor
                    border.width: 2
                    border.color: root.surfaceColor
                }
            }

            handle: Rectangle {
                visible: false
            }
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
