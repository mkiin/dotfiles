import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices
import "../../../config" as QsConfig

Item {
    readonly property var sysUsage: QsServices.SystemUsage
    readonly property int chartAnimDuration: 800
    readonly property int legendSwatchRadius: 2

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: QsConfig.Appearance.margin.l
        spacing: QsConfig.Appearance.spacing.xl
        
        Text {
            text: "System Performance"
            font.family: QsConfig.Appearance.typography.family
            font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
            font.weight: Font.Bold
            color: QsConfig.Theme.text
        }
        
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rowSpacing: QsConfig.Appearance.spacing.m
            columnSpacing: QsConfig.Appearance.spacing.m
            
            // CPU Usage
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 100
                radius: QsConfig.Appearance.radius.s
                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: QsConfig.Appearance.margin.m
                    spacing: QsConfig.Appearance.spacing.s
                    
                    Text {
                        text: "CPU"
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                        font.weight: Font.DemiBold
                        color: QsConfig.Theme.text
                    }
                    
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        Canvas {
                            id: cpuChart
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.85
                            height: width
                            
                            property real percentage: sysUsage.cpuPerc * 100
                            property real animatedPercentage: 0
                            
                            Behavior on animatedPercentage {
                                NumberAnimation { duration: chartAnimDuration; easing.type: Easing.OutCubic }
                            }
                            
                            onPercentageChanged: animatedPercentage = percentage
                            Component.onCompleted: animatedPercentage = percentage
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = Math.min(width, height) / 2 - 5
                                
                                // Background circle
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                                ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
                                ctx.fill()
                                
                                // Usage arc
                                var angle = (animatedPercentage / 100) * 2 * Math.PI
                                ctx.beginPath()
                                ctx.moveTo(centerX, centerY)
                                ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + angle)
                                ctx.closePath()
                                
                                // Color based on usage
                                if (animatedPercentage < 50) {
                                    ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.tertiary, 0.8)
                                } else if (animatedPercentage < 80) {
                                    ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.secondary, 0.8)
                                } else {
                                    ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.error, 0.8)
                                }
                                ctx.fill()
                                
                                // Inner circle (donut)
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius * 0.6, 0, 2 * Math.PI)
                                ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                                ctx.fill()
                            }
                            
                            onAnimatedPercentageChanged: requestPaint()
                        }
                        
                        Text {
                            anchors.centerIn: cpuChart
                            text: Math.round(sysUsage.cpuPerc * 100) + "%"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                            font.weight: Font.Bold
                            color: QsConfig.Theme.text
                        }
                    }
                }
            }
            
            // Memory Usage
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 100
                radius: QsConfig.Appearance.radius.s
                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: QsConfig.Appearance.margin.m
                    spacing: QsConfig.Appearance.spacing.s
                    
                    Text {
                        text: "Memory"
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                        font.weight: Font.DemiBold
                        color: QsConfig.Theme.text
                    }
                    
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        Canvas {
                            id: memChart
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.85
                            height: width
                            
                            property real percentage: sysUsage.memPerc * 100
                            property real animatedPercentage: 0
                            
                            Behavior on animatedPercentage {
                                NumberAnimation { duration: chartAnimDuration; easing.type: Easing.OutCubic }
                            }
                            
                            onPercentageChanged: animatedPercentage = percentage
                            Component.onCompleted: animatedPercentage = percentage
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = Math.min(width, height) / 2 - 5
                                
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                                ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
                                ctx.fill()
                                
                                var angle = (animatedPercentage / 100) * 2 * Math.PI
                                ctx.beginPath()
                                ctx.moveTo(centerX, centerY)
                                ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + angle)
                                ctx.closePath()
                                
                                if (animatedPercentage < 50) {
                                    ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.tertiary, 0.8)
                                } else if (animatedPercentage < 80) {
                                    ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.secondary, 0.8)
                                } else {
                                    ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.error, 0.8)
                                }
                                ctx.fill()
                                
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius * 0.6, 0, 2 * Math.PI)
                                ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                                ctx.fill()
                            }
                            
                            onAnimatedPercentageChanged: requestPaint()
                        }
                        
                        Text {
                            anchors.centerIn: memChart
                            text: Math.round(sysUsage.memPerc * 100) + "%"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                            font.weight: Font.Bold
                            color: QsConfig.Theme.text
                        }
                    }
                }
            }
            
            // Disk Usage
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 100
                radius: QsConfig.Appearance.radius.s
                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: QsConfig.Appearance.margin.m
                    spacing: QsConfig.Appearance.spacing.s
                    
                    Text {
                        text: "Disk"
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                        font.weight: Font.DemiBold
                        color: QsConfig.Theme.text
                    }
                    
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        Canvas {
                            id: diskChart
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.85
                            height: width
                            
                            property real percentage: sysUsage.diskPerc * 100
                            property real animatedPercentage: 0
                            
                            Behavior on animatedPercentage {
                                NumberAnimation { duration: chartAnimDuration; easing.type: Easing.OutCubic }
                            }
                            
                            onPercentageChanged: animatedPercentage = percentage
                            Component.onCompleted: animatedPercentage = percentage
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = Math.min(width, height) / 2 - 5
                                
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                                ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
                                ctx.fill()
                                
                                var angle = (animatedPercentage / 100) * 2 * Math.PI
                                ctx.beginPath()
                                ctx.moveTo(centerX, centerY)
                                ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + angle)
                                ctx.closePath()
                                
                                if (animatedPercentage < 50) {
                                    ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.tertiary, 0.8)
                                } else if (animatedPercentage < 80) {
                                    ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.secondary, 0.8)
                                } else {
                                    ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.error, 0.8)
                                }
                                ctx.fill()
                                
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius * 0.6, 0, 2 * Math.PI)
                                ctx.fillStyle = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                                ctx.fill()
                            }
                            
                            onAnimatedPercentageChanged: requestPaint()
                        }
                        
                        Text {
                            anchors.centerIn: diskChart
                            text: Math.round(sysUsage.diskPerc * 100) + "%"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                            font.weight: Font.Bold
                            color: QsConfig.Theme.text
                        }
                    }
                }
            }
            
            // Legend
            Rectangle {
                Layout.fillWidth: true
                Layout.columnSpan: 3
                Layout.preferredHeight: 60
                radius: QsConfig.Appearance.radius.s
                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: QsConfig.Appearance.spacing.l
                    
                    RowLayout {
                        spacing: QsConfig.Appearance.spacing.s
                        Rectangle {
                            width: 10
                            height: 10
                            radius: legendSwatchRadius
                            color: QsConfig.Theme.tertiary
                        }
                        Text {
                            text: "Good (< 50%)"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                            color: QsConfig.Theme.text
                        }
                    }
                    
                    RowLayout {
                        spacing: QsConfig.Appearance.spacing.s
                        Rectangle {
                            width: 10
                            height: 10
                            radius: legendSwatchRadius
                            color: QsConfig.Theme.secondary
                        }
                        Text {
                            text: "Moderate (50-80%)"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                            color: QsConfig.Theme.text
                        }
                    }
                    
                    RowLayout {
                        spacing: QsConfig.Appearance.spacing.s
                        Rectangle {
                            width: 10
                            height: 10
                            radius: legendSwatchRadius
                            color: QsConfig.Theme.error
                        }
                        Text {
                            text: "High (> 80%)"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                            color: QsConfig.Theme.text
                        }
                    }
                }
                }
            }
        }
    }
}
