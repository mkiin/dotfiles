import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../components/effects"
import "../../../config" as QsConfig

Rectangle {
    id: root
    
    required property var systemUsage
    readonly property int rowSpacing: 0

    // Color tokens
    readonly property color surfaceColor: QsConfig.Theme.card
    readonly property color textColor: QsConfig.Theme.text
    readonly property color textDim: QsConfig.Theme.textDim
    
    Layout.fillWidth: true
    Layout.preferredHeight: 86
    
    radius: QsConfig.Appearance.radius.l
    color: surfaceColor
    
    Behavior on color {
        ColorAnimation {
            duration: Material3Anim.medium2
            easing.bezierCurve: Material3Anim.standard
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: QsConfig.Appearance.margin.m
        anchors.rightMargin: QsConfig.Appearance.margin.m
        anchors.topMargin: QsConfig.Appearance.margin.s
        anchors.bottomMargin: QsConfig.Appearance.margin.s
        spacing: root.rowSpacing
        
        Item { Layout.fillWidth: true }
        
        StatItem {
            icon: "󰘚"
            label: "CPU"
            value: (root.systemUsage.cpuPerc ?? 0) * 100
            accentColor: QsConfig.Theme.accent
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
            accentColor: QsConfig.Theme.secondary
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
            accentColor: QsConfig.Theme.info
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
            accentColor: QsConfig.Theme.tertiary
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

        spacing: QsConfig.Appearance.spacing.xs
        
        // Icon + Value row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: QsConfig.Appearance.spacing.s
            
            Text {
                text: icon
                font.family: QsConfig.Appearance.typography.iconFamily
                font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                color: accentColor
            }
            
            Text {
                text: Math.round(value) + "%"
                font.family: QsConfig.Appearance.typography.family
                font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
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
                        duration: Material3Anim.medium2
                        easing.bezierCurve: Material3Anim.emphasizedDecelerate
                    }
                }
            }
        }
        
        // Label
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: label
            font.family: QsConfig.Appearance.typography.family
            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
            font.weight: Font.Medium
            color: root.textDim
        }
    }
}
