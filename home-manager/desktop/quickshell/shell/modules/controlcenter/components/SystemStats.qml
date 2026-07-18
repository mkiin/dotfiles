import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../theme" as QsTheme

Rectangle {
    id: root
    
    required property var systemUsage
    readonly property int rowSpacing: 0

    // Color tokens
    readonly property color surfaceColor: QsTheme.Theme.card
    readonly property color textColor: QsTheme.Theme.text
    readonly property color textDim: QsTheme.Theme.textDim
    
    Layout.fillWidth: true
    Layout.preferredHeight: 86
    
    radius: QsTheme.Appearance.radius.l
    color: surfaceColor
    
    Behavior on color {
        ColorAnimation {
            duration: QsTheme.Appearance.anim.durations.medium2
            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: QsTheme.Appearance.margin.m
        anchors.rightMargin: QsTheme.Appearance.margin.m
        anchors.topMargin: QsTheme.Appearance.margin.s
        anchors.bottomMargin: QsTheme.Appearance.margin.s
        spacing: root.rowSpacing
        
        Item { Layout.fillWidth: true }
        
        StatItem {
            icon: "󰘚"
            label: "CPU"
            value: (root.systemUsage.cpuPerc ?? 0) * 100
            accentColor: QsTheme.Theme.accent
        }
        
        Item { Layout.fillWidth: true }
        
        // Separator
        Rectangle {
            width: 1
            height: 40
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
        }
        
        Item { Layout.fillWidth: true }
        
        StatItem {
            icon: "󰍛"
            label: "RAM"
            value: (root.systemUsage.memPerc ?? 0) * 100
            accentColor: QsTheme.Theme.secondary
        }
        
        Item { Layout.fillWidth: true }
        
        Rectangle {
            width: 1
            height: 40
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
        }
        
        Item { Layout.fillWidth: true }
        
        StatItem {
            icon: "󰋊"
            label: "Disk"
            value: (root.systemUsage.diskPerc ?? 0) * 100
            accentColor: QsTheme.Theme.info
        }
        
        Item { Layout.fillWidth: true }
        
        // GPU (if available)
        Rectangle {
            visible: root.systemUsage.hasGpu
            width: 1
            height: 40
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
        }
        
        Item { 
            Layout.fillWidth: true 
            visible: root.systemUsage.hasGpu
        }
        
        StatItem {
            visible: root.systemUsage.hasGpu
            icon: "󰢮"
            label: "GPU"
            value: root.systemUsage.gpuUsage ?? 0
            accentColor: QsTheme.Theme.tertiary
        }
        
        Item { 
            Layout.fillWidth: true 
            visible: root.systemUsage.hasGpu
        }
    }
    
    component StatItem: ColumnLayout {
        property string icon
        property string label
        property real value
        property color accentColor

        spacing: QsTheme.Appearance.spacing.xs
        
        // Icon + Value row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: QsTheme.Appearance.spacing.s
            
            Text {
                text: icon
                font.family: QsTheme.Appearance.typography.iconFamily
                font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                color: accentColor
            }
            
            Text {
                text: Math.round(value) + "%"
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                font.weight: Font.Bold
                color: root.textColor
                
                Behavior on text {
                    enabled: false
                }
            }
        }
        
        // Progress bar
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 56
            Layout.preferredHeight: 4
            radius: height / 2
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
            
            Rectangle {
                width: parent.width * Math.min(value / 100, 1)
                height: parent.height
                radius: height / 2
                color: accentColor
                
                Behavior on width {
                    NumberAnimation {
                        duration: QsTheme.Appearance.anim.durations.medium2
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.emphasizedDecel
                    }
                }
            }
        }
        
        // Label
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: label
            font.family: QsTheme.Appearance.typography.family
            font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
            font.weight: Font.Medium
            color: root.textDim
        }
    }
}
