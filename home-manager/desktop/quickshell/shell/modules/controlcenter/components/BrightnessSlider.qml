import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../components/effects"
import "../../../config" as QsConfig

Rectangle {
    id: root
    
    required property var brightness
    readonly property int rowSpacing: 0

    // Current brightness value
    readonly property int currentBrightness: brightness ? Math.round((brightness.percentage ?? 0)) : 0
    
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
        
        // Icon
        Rectangle {
            id: iconBtn
            Layout.preferredWidth: 52
            Layout.fillHeight: true
            radius: QsConfig.Appearance.radius.l
            color: iconMouse.containsMouse 
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
                text: root.currentBrightness > 70 ? "󰃠" : (root.currentBrightness > 30 ? "󰃟" : "󰃞")
                font.family: QsConfig.Appearance.typography.iconFamily
                font.pixelSize: QsConfig.Appearance.typography.titleLarge.size
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
            Layout.rightMargin: QsConfig.Appearance.margin.m

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
                            duration: Material3Anim.short2
                            easing.bezierCurve: Material3Anim.standard
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
