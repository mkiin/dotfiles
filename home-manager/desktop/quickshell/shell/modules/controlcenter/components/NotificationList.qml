import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import "../../../theme" as QsTheme

Rectangle {
    id: root
    
    required property var notifs
    readonly property int emptyIconSize: 48

    // Solid color tokens (Theme)
    
    implicitHeight: Math.max(contentCol.implicitHeight + 32, 160)

    radius: QsTheme.Appearance.radius.l
    color: QsTheme.Theme.inset
    border.color: QsTheme.Theme.card
    border.width: 1
    
    Behavior on color {
        ColorAnimation {
            duration: QsTheme.Appearance.anim.durations.medium2
            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
        }
    }
    
    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: QsTheme.Appearance.margin.m
        spacing: QsTheme.Appearance.spacing.m
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "Notifications"
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                font.weight: Font.Bold
                color: QsTheme.Theme.text
            }
            
            Item { Layout.fillWidth: true }
            
            // Clear All Button
            Rectangle {
                id: clearAllBtn
                visible: (notifs.recentNotifications?.length ?? 0) > 0
                width: clearAllText.implicitWidth + 16
                height: 28
                radius: height / 2
                color: clearAllMouse.containsMouse 
                    ? QsTheme.Theme.cardHigh
                    : QsTheme.Theme.card
                
                Behavior on color {
                    ColorAnimation {
                        duration: QsTheme.Appearance.anim.durations.short3
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }
                
                Text {
                    id: clearAllText
                    anchors.centerIn: parent
                    text: "Clear All"
                    font.family: QsTheme.Appearance.typography.family
                    font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                    font.weight: Font.Medium
                    color: QsTheme.Theme.textVariant
                }
                
                MouseArea {
                    id: clearAllMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: notifs.clearAll()
                }
            }
        }
        
        // List
        ListView {
            id: notifListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: (notifs.recentNotifications?.length ?? 0) > 0 ? notifListView.contentHeight : 120
            Layout.minimumHeight: 0
            clip: true
            spacing: QsTheme.Appearance.spacing.s

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 4
            }
            
            model: notifs.recentNotifications ?? []
            
            // Smooth add/remove animations
            add: Transition {
                NumberAnimation { 
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: QsTheme.Appearance.anim.durations.medium2
                    easing.bezierCurve: QsTheme.Appearance.anim.curves.emphasizedDecel
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.95
                    to: 1.0
                    duration: QsTheme.Appearance.anim.durations.medium2
                    easing.bezierCurve: QsTheme.Appearance.anim.curves.emphasizedDecel
                }
            }
            
            remove: Transition {
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: QsTheme.Appearance.anim.durations.short4
                    easing.bezierCurve: QsTheme.Appearance.anim.curves.emphasizedAccel
                }
            }
            
            delegate: Rectangle {
                id: notifDelegate
                required property var modelData
                required property int index
                
                width: notifListView.width
                height: notifContent.implicitHeight + 20
                radius: QsTheme.Appearance.radius.m
                color: notifMouse.containsMouse 
                    ? QsTheme.Theme.card
                    : QsTheme.Theme.card
                
                Behavior on color {
                    ColorAnimation {
                        duration: QsTheme.Appearance.anim.durations.short3
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }
                
                // Press scale
                scale: notifMouse.pressed ? 0.98 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: QsTheme.Appearance.anim.durations.short2
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }
                
                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.actions && modelData.actions.length > 0) {
                            modelData.actions[0].invoke()
                        }
                    }
                }
                
                RowLayout {
                    id: notifContent
                    anchors.fill: parent
                    anchors.margins: QsTheme.Appearance.margin.s
                    spacing: QsTheme.Appearance.spacing.m
                    
                    // Icon
                    Item {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        Layout.alignment: Qt.AlignTop

                        // 地の色だけを薄くするため背景を子に分ける
                        Rectangle {
                            anchors.fill: parent
                            radius: QsTheme.Appearance.radius.s
                            color: QsTheme.Theme.primary
                            opacity: 0.15
                        }
                        
                        Image {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: notifDelegate.modelData.appIcon 
                                ? (notifDelegate.modelData.appIcon.startsWith("/") 
                                    ? notifDelegate.modelData.appIcon 
                                    : "image://icon/" + notifDelegate.modelData.appIcon) 
                                : ""
                            visible: status === Image.Ready
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰂚"
                            font.family: QsTheme.Appearance.typography.iconFamily
                            font.pixelSize: QsTheme.Appearance.typography.titleLarge.size
                            color: QsTheme.Theme.primary
                            visible: !parent.children[0].visible
                        }
                    }
                    
                    // Text Content
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: QsTheme.Appearance.spacing.xs
                        
                        Text {
                            text: notifDelegate.modelData.summary ?? "Notification"
                            font.family: QsTheme.Appearance.typography.family
                            font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                            font.weight: Font.DemiBold
                            color: QsTheme.Theme.text
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        
                        Text {
                            text: notifDelegate.modelData.body ?? ""
                            font.family: QsTheme.Appearance.typography.family
                            font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                            color: QsTheme.Theme.textVariant
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            visible: text !== ""
                        }
                        
                        Text {
                            text: notifDelegate.modelData.appName ?? ""
                            font.family: QsTheme.Appearance.typography.family
                            font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                            color: QsTheme.Theme.textVariant
                            Layout.fillWidth: true
                            visible: text !== ""
                        }
                    }
                    
                    // Close button
                    Rectangle {
                        id: closeBtn
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignTop
                        radius: height / 2
                        color: closeMouse.containsMouse 
                            ? QsTheme.Theme.border
                            : "transparent"
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: QsTheme.Appearance.anim.durations.short2
                                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: QsTheme.Appearance.typography.iconFamily
                            font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                            color: closeMouse.containsMouse
                                ? QsTheme.Theme.text 
                                : QsTheme.Theme.textVariant
                            
                            Behavior on color {
                                ColorAnimation {
                                    duration: QsTheme.Appearance.anim.durations.short2
                                    easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                                }
                            }
                        }
                        
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: notifDelegate.modelData.close()
                        }
                    }
                }
            }
            
            // Empty State
            ColumnLayout {
                anchors.centerIn: parent
                spacing: QsTheme.Appearance.spacing.s
                visible: (notifs.recentNotifications?.length ?? 0) === 0
                opacity: visible ? 1 : 0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: QsTheme.Appearance.anim.durations.medium2
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰂚"
                    font.family: QsTheme.Appearance.typography.iconFamily
                    font.pixelSize: root.emptyIconSize
                    color: QsTheme.Theme.border
                }
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No Notifications"
                    font.family: QsTheme.Appearance.typography.family
                    font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                    font.weight: Font.Medium
                    color: QsTheme.Theme.textVariant
                }
            }
        }
    }
}
