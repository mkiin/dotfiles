import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import "../../../theme" as QsTheme
import "../../../services" as QsServices
import "../../../utils" as QsUtils

Item {
    id: root

    readonly property var notifs: QsServices.Notifs

    readonly property color textColor: QsTheme.Theme.text
    readonly property color accentColor: QsTheme.Theme.accent
    readonly property color urgentColor: QsTheme.Theme.error
    readonly property color surfaceColor: QsTheme.Theme.background
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: QsTheme.Appearance.margin.l
        spacing: QsTheme.Appearance.spacing.l
        
        // Header with title and actions
        RowLayout {
            Layout.fillWidth: true
            spacing: QsTheme.Appearance.spacing.m
            
            Text {
                text: "Notifications"
                font.pixelSize: QsTheme.Appearance.typography.titleLarge.size
                font.weight: Font.Bold
                color: root.textColor
                Layout.fillWidth: true
            }
            
            // DND Toggle
            Rectangle {
                width: 36
                height: 36
                radius: height / 2
                color: notifs.dnd ? root.accentColor : Qt.rgba(1, 1, 1, 0.1)
                
                Text {
                    anchors.centerIn: parent
                    text: notifs.dnd ? "󰂛" : "󰂚"
                    font.family: QsTheme.Appearance.typography.iconFamily
                    font.pixelSize: QsTheme.Appearance.typography.titleMedium.size
                    color: notifs.dnd ? "#000000" : root.textColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notifs.toggleDnd()
                }
                
                Behavior on color {
                    ColorAnimation { duration: QsTheme.Appearance.anim.durations.normal }
                }
            }
            
            // Clear All Button
            Rectangle {
                width: 36
                height: 36
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.1)
                visible: (notifs.recentNotifications?.length ?? 0) > 0
                
                Text {
                    anchors.centerIn: parent
                    text: "󰎟"
                    font.family: QsTheme.Appearance.typography.iconFamily
                    font.pixelSize: QsTheme.Appearance.typography.titleMedium.size
                    color: root.textColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        QsUtils.Logger.debug("NotificationsSection", "Clearing all notifications")
                        notifs.clearAll()
                    }
                }
            }
        }
        
        // Notifications List
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.2)
            radius: QsTheme.Appearance.radius.s
            
            ListView {
                id: notificationsList
                
                anchors.fill: parent
                anchors.margins: QsTheme.Appearance.margin.s
                spacing: QsTheme.Appearance.spacing.s
                clip: true
                
                model: notifs.recentNotifications ?? []
                
                // Empty state
                Text {
                    anchors.centerIn: parent
                    visible: notificationsList.count === 0
                    text: notifs.dnd ? "Do Not Disturb is enabled\n󰂛" : "No notifications\n󰂚"
                    font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                    color: Qt.rgba(root.textColor.r,
                                   root.textColor.g, 
                                   root.textColor.b, 0.5)
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.4
                }
                
                delegate: Rectangle {
                    id: notifItem
                    
                    required property var modelData
                    
                    width: notificationsList.width
                    height: contentColumn.height + 16
                    radius: QsTheme.Appearance.radius.s
                    color: modelData.urgency === 2 ? 
                           Qt.rgba(root.urgentColor.r,
                                  root.urgentColor.g,
                                  root.urgentColor.b, 0.2) :
                           Qt.rgba(1, 1, 1, 0.05)
                    
                    // Slightly dimmed if closed (viewed)
                    opacity: modelData.closed ? 0.5 : 1.0
                    
                    // Border for unread notifications
                    border.width: modelData.closed ? 0 : 1
                    border.color: Qt.rgba(root.accentColor.r, 
                                         root.accentColor.g, 
                                         root.accentColor.b, 0.3)
                    
                    // Hover effect
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.rgba(1, 1, 1, 0.05)
                        opacity: notifMouseArea.containsMouse ? 1 : 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                        }
                    }
                    
                    MouseArea {
                        id: notifMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                    
                    ColumnLayout {
                        id: contentColumn
                        
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: QsTheme.Appearance.margin.m
                        spacing: QsTheme.Appearance.spacing.s
                        
                        // Header: App icon, name, time, close button
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: QsTheme.Appearance.spacing.s
                            
                            // App Icon
                            Rectangle {
                                width: 24
                                height: 24
                                radius: QsTheme.Appearance.radius.xs
                                color: Qt.rgba(1, 1, 1, 0.1)
                                visible: modelData.appIcon.length > 0
                                
                                Image {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: modelData.appIcon
                                    fillMode: Image.PreserveAspectFit
                                }
                            }
                            
                            // App Name
                            Text {
                                text: modelData.appName || "Application"
                                font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                                font.weight: Font.Medium
                                color: root.textColor
                                opacity: 0.7
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            // Timestamp
                            Text {
                                text: modelData.timeString
                                font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                                color: root.textColor
                                opacity: 0.5
                            }
                            
                            // Close button
                            Rectangle {
                                width: 24
                                height: 24
                                radius: height / 2
                                color: closeMouseArea.containsMouse ? 
                                       Qt.rgba(1, 1, 1, 0.2) : "transparent"
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: QsTheme.Appearance.typography.iconFamily
                                    font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                                    color: root.textColor
                                }
                                
                                MouseArea {
                                    id: closeMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        QsUtils.Logger.debug("NotificationsSection", `Deleting notification: ${modelData.summary}`)
                                        notifs.deleteNotification(modelData)
                                    }
                                }
                                
                                Behavior on color {
                                    ColorAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                                }
                            }
                        }
                        
                        // Summary
                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary
                            font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                            font.weight: Font.DemiBold
                            color: root.textColor
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        
                        // Body
                        Text {
                            Layout.fillWidth: true
                            text: modelData.body
                            font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                            color: root.textColor
                            opacity: 0.8
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            visible: modelData.body.length > 0
                        }
                        
                        // Image
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            radius: QsTheme.Appearance.radius.s
                            clip: true
                            visible: modelData.image.length > 0
                            color: "transparent"
                            
                            Image {
                                anchors.fill: parent
                                source: modelData.image
                                fillMode: Image.PreserveAspectCrop
                            }
                        }
                        
                        // Actions
                        Flow {
                            Layout.fillWidth: true
                            spacing: QsTheme.Appearance.spacing.s
                            visible: modelData.actions && modelData.actions.length > 0
                            
                            Repeater {
                                model: modelData.actions || []
                                
                                Rectangle {
                                    width: actionText.width + 16
                                    height: 28
                                    radius: QsTheme.Appearance.radius.xs
                                    color: actionMouseArea.containsMouse ?
                                           root.accentColor :
                                           Qt.rgba(1, 1, 1, 0.1)
                                    
                                    Text {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: modelData.text || modelData.identifier
                                        font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                                        font.weight: Font.Medium
                                        color: actionMouseArea.containsMouse ?
                                               "#000000" : root.textColor
                                    }
                                    
                                    MouseArea {
                                        id: actionMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            notifItem.modelData.invokeAction(modelData.identifier);
                                            notifItem.modelData.close();
                                        }
                                    }
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // DND Status Text
        Text {
            Layout.fillWidth: true
            text: notifs.dnd ? "󰂛 Do Not Disturb enabled - notifications are silenced" : ""
            font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
            color: root.accentColor
            horizontalAlignment: Text.AlignHCenter
            visible: notifs.dnd
            opacity: 0.8
        }
    }
}
