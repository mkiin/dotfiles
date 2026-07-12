import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../components/effects"
import "../../../config" as QsConfig

Rectangle {
    id: root
    
    property string icon: ""
    property string label: ""
    property string subLabel: ""
    property bool active: false
    property color activeColor: "#a6e3a1"
    property color surfaceColor: Qt.rgba(0.15, 0.15, 0.18, 1)
    property color textColor: "#e6e6e6"
    signal clicked()

    readonly property color onActiveColor: (0.2126 * activeColor.r + 0.7152 * activeColor.g + 0.0722 * activeColor.b) > 0.55
        ? Qt.rgba(0.05, 0.06, 0.08, 1)
        : Qt.rgba(1, 1, 1, 1)
    
    Layout.fillWidth: true
    Layout.preferredHeight: 72

    radius: QsConfig.Appearance.radius.l
    clip: true

    color: active ? activeColor : surfaceColor
    border.width: 1
    border.color: active
        ? "transparent"
        : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)
    
    // Smooth M3 color transition
    Behavior on color {
        ColorAnimation { 
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.standard
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Material3Anim.short4
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    // Press scale animation
    scale: toggleMouse.pressed ? 0.98 : toggleMouse.containsMouse ? Material3Anim.hoverScale : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Material3Anim.short2
            easing.bezierCurve: Material3Anim.springGentle
        }
    }

    // Hover state overlay
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
            color: root.active
                ? Qt.rgba(root.onActiveColor.r, root.onActiveColor.g, root.onActiveColor.b, 0.10)
                : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.06)
        opacity: toggleMouse.containsMouse && !toggleMouse.pressed ? 1 : 0
        
        Behavior on opacity {
            NumberAnimation {
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }
    }
    
    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: QsConfig.Appearance.margin.l
        anchors.rightMargin: QsConfig.Appearance.margin.l
        spacing: QsConfig.Appearance.spacing.l
        
        // Icon Circle
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: height / 2
            color: active
                ? Qt.rgba(root.onActiveColor.r, root.onActiveColor.g, root.onActiveColor.b, 0.16)
                : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.10)
            
            Behavior on color {
                ColorAnimation {
                    duration: Material3Anim.short4
                    easing.bezierCurve: Material3Anim.standard
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: QsConfig.Appearance.typography.iconFamily
                font.pixelSize: QsConfig.Appearance.typography.titleLarge.size
                color: root.active ? root.onActiveColor : root.textColor
                
                Behavior on color {
                    ColorAnimation {
                        duration: Material3Anim.short4
                        easing.bezierCurve: Material3Anim.standard
                    }
                }
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: QsConfig.Appearance.spacing.xs
            
            Text {
                text: root.label
                font.family: QsConfig.Appearance.typography.family
                font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                font.weight: Font.DemiBold
                color: root.active ? root.onActiveColor : root.textColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                
                Behavior on color {
                    ColorAnimation {
                        duration: Material3Anim.short4
                        easing.bezierCurve: Material3Anim.standard
                    }
                }
            }
            
            Text {
                text: root.subLabel
                font.family: QsConfig.Appearance.typography.family
                font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                color: active
                    ? Qt.rgba(root.onActiveColor.r, root.onActiveColor.g, root.onActiveColor.b, 0.78)
                    : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
                
                Behavior on color {
                    ColorAnimation {
                        duration: Material3Anim.short4
                        easing.bezierCurve: Material3Anim.standard
                    }
                }
            }
        }
    }
}
