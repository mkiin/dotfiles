import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../theme" as QsTheme

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

    radius: QsTheme.Appearance.radius.l
    clip: true

    color: active ? activeColor : surfaceColor
    border.width: 1
    border.color: active
        ? "transparent"
        : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.12)
    
    // Smooth M3 color transition
    Behavior on color {
        ColorAnimation { 
            duration: QsTheme.Appearance.anim.durations.medium2
            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: QsTheme.Appearance.anim.durations.short4
            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
        }
    }
    
    // Press scale animation
    scale: toggleMouse.pressed ? 0.98 : toggleMouse.containsMouse ? QsTheme.Appearance.anim.hoverScale : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: QsTheme.Appearance.anim.durations.short2
            easing.bezierCurve: QsTheme.Appearance.anim.curves.springGentle
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
                duration: QsTheme.Appearance.anim.durations.short3
                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
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
        anchors.leftMargin: QsTheme.Appearance.margin.l
        anchors.rightMargin: QsTheme.Appearance.margin.l
        spacing: QsTheme.Appearance.spacing.l
        
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
                    duration: QsTheme.Appearance.anim.durations.short4
                    easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: QsTheme.Appearance.typography.iconFamily
                font.pixelSize: QsTheme.Appearance.typography.titleLarge.size
                color: root.active ? root.onActiveColor : root.textColor
                
                Behavior on color {
                    ColorAnimation {
                        duration: QsTheme.Appearance.anim.durations.short4
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: QsTheme.Appearance.spacing.xs
            
            Text {
                text: root.label
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                font.weight: Font.DemiBold
                color: root.active ? root.onActiveColor : root.textColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                
                Behavior on color {
                    ColorAnimation {
                        duration: QsTheme.Appearance.anim.durations.short4
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }
            }
            
            Text {
                text: root.subLabel
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                color: active
                    ? Qt.rgba(root.onActiveColor.r, root.onActiveColor.g, root.onActiveColor.b, 0.78)
                    : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
                
                Behavior on color {
                    ColorAnimation {
                        duration: QsTheme.Appearance.anim.durations.short4
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }
            }
        }
    }
}
