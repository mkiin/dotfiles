import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Io
import "../../../services" as QsServices
import "../../../utils" as QsUtils
import "../../../config" as QsConfig

Item {
    id: root
    
    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness
    readonly property var network: QsServices.Network
    readonly property var bluetooth: QsServices.Bluetooth
    readonly property var idleInhibitor: QsServices.IdleInhibitor

    Process { id: lockProc; command: ["loginctl", "lock-session"] }
    Process { id: logoutProc; command: ["hyprctl", "dispatch", "exit"] }
    Process { id: sleepProc; command: ["systemctl", "suspend"] }
    Process { id: wifiSettingsProc; command: ["nm-connection-editor"] }
    Process { id: bluetoothSettingsProc; command: ["blueman-manager"] }
    
    // DND state (simple toggle for now)
    property bool dndEnabled: false
    
    ScrollView {
        anchors.fill: parent
        anchors.margins: QsConfig.Appearance.margin.m
        clip: true
        
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        
        ColumnLayout {
            width: parent.parent.width - 32
            spacing: QsConfig.Appearance.spacing.l
            
            // Power buttons section
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: QsConfig.Appearance.spacing.s
                columnSpacing: QsConfig.Appearance.spacing.s
                
                // Lock button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: QsConfig.Appearance.radius.s
                    color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: QsConfig.Appearance.spacing.s
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰌾"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.headlineMedium.size
                            color: QsConfig.Theme.secondary
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Lock"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                            color: QsConfig.Theme.text
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            lockProc.running = true
                        }
                        
                        onPressed: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
                        onReleased: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                    }
                }
                
                // Logout button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: QsConfig.Appearance.radius.s
                    color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: QsConfig.Appearance.spacing.s
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰗼"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.headlineMedium.size
                            color: QsConfig.Theme.tertiary
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Logout"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                            color: QsConfig.Theme.text
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            logoutProc.running = true
                        }
                        
                        onPressed: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
                        onReleased: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                    }
                }
                
                // Sleep button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: QsConfig.Appearance.radius.s
                    color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: QsConfig.Appearance.spacing.s
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰒲"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.headlineMedium.size
                            color: QsConfig.Theme.text
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Sleep"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                            color: QsConfig.Theme.text
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            sleepProc.running = true
                        }
                        
                        onPressed: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
                        onReleased: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                    }
                }
                
                // Power off button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: QsConfig.Appearance.radius.s
                    color: QsConfig.Theme.withAlpha(QsConfig.Theme.error, 0.1)
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: QsConfig.Appearance.spacing.s
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰐥"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.headlineMedium.size
                            color: QsConfig.Theme.error
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Power"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                            color: QsConfig.Theme.text
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            QsUtils.Logger.debug("SettingsSection", "Power off")
                        }
                        
                        onPressed: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.error, 0.15)
                        onReleased: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.error, 0.1)
                    }
                }
            }
            
            // Separator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
            }
            
            // Quick toggles
            Text {
                text: "Quick Settings"
                font.family: QsConfig.Appearance.typography.family
                font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                font.weight: Font.DemiBold
                color: QsConfig.Theme.text
            }
            
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: QsConfig.Appearance.spacing.s
                columnSpacing: QsConfig.Appearance.spacing.s
                
                // DND Toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: QsConfig.Appearance.radius.s
                    color: dndEnabled ? 
                           QsConfig.Theme.withAlpha(QsConfig.Theme.error, 0.15) : 
                           QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                    
                    Behavior on color {
                        ColorAnimation { duration: QsConfig.Appearance.anim.durations.normal; easing.type: Easing.OutCubic }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: QsConfig.Appearance.margin.m
                        spacing: QsConfig.Appearance.spacing.m
                        
                        Text {
                            text: "󰂛"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.headlineSmall.size
                            color: dndEnabled ? QsConfig.Theme.error : QsConfig.Theme.text
                            
                            Behavior on color {
                                ColorAnimation { duration: QsConfig.Appearance.anim.durations.normal; easing.type: Easing.OutCubic }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: QsConfig.Appearance.spacing.xs
                            
                            Text {
                                text: "Do Not Disturb"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                                font.weight: Font.Medium
                                color: QsConfig.Theme.text
                            }
                            
                            Text {
                                text: dndEnabled ? "On" : "Off"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.6)
                            }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dndEnabled = !dndEnabled
                    }
                }
                
                // Idle Inhibitor Toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: QsConfig.Appearance.radius.s
                    color: idleInhibitor.inhibited ? 
                           QsConfig.Theme.withAlpha(QsConfig.Theme.tertiary, 0.15) : 
                           QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                    
                    Behavior on color {
                        ColorAnimation { duration: QsConfig.Appearance.anim.durations.normal; easing.type: Easing.OutCubic }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: QsConfig.Appearance.margin.m
                        spacing: QsConfig.Appearance.spacing.m
                        
                        Text {
                            text: idleInhibitor.inhibited ? "󰅶" : "󰾪"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.headlineSmall.size
                            color: idleInhibitor.inhibited ? QsConfig.Theme.tertiary : QsConfig.Theme.text
                            
                            Behavior on color {
                                ColorAnimation { duration: QsConfig.Appearance.anim.durations.normal; easing.type: Easing.OutCubic }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: QsConfig.Appearance.spacing.xs
                            
                            Text {
                                text: "Keep Awake"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                                font.weight: Font.Medium
                                color: QsConfig.Theme.text
                            }
                            
                            Text {
                                text: idleInhibitor.inhibited ? "On" : "Off"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.6)
                            }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: idleInhibitor.inhibited = !idleInhibitor.inhibited
                    }
                }
            }
            
            // Separator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
            }
            
            // Network Controls
            Text {
                text: "Network"
                font.family: QsConfig.Appearance.typography.family
                font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                font.weight: Font.DemiBold
                color: QsConfig.Theme.text
            }
            
            // WiFi Control
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: QsConfig.Appearance.radius.s
                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: QsConfig.Appearance.margin.m
                    spacing: QsConfig.Appearance.spacing.m
                    
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: height / 2
                        color: network.connected ? QsConfig.Theme.withAlpha(QsConfig.Theme.tertiary, 0.2) : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: network.connected ? "󰖩" : "󰖪"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.titleLarge.size
                            color: network.connected ? QsConfig.Theme.tertiary : QsConfig.Theme.text
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: QsConfig.Appearance.spacing.xs
                        
                        Text {
                            text: network.connected ? network.ssid : "WiFi Disconnected"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                            font.weight: Font.Medium
                            color: QsConfig.Theme.text
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        
                        Text {
                            text: network.connected ? "Connected" : "Click to connect"
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                            color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.6)
                        }
                    }
                    
                    Text {
                        text: "󰅂"
                        font.family: QsConfig.Appearance.typography.iconFamily
                        font.pixelSize: QsConfig.Appearance.typography.titleMedium.size
                        color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.5)
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wifiSettingsProc.running = true
                    }
                    
                    onPressed: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
                    onReleased: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                }
            }
            
            // Bluetooth Control
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: QsConfig.Appearance.radius.s
                color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: QsConfig.Appearance.margin.m
                    spacing: QsConfig.Appearance.spacing.m
                    
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: height / 2
                        color: bluetooth.connected ? QsConfig.Theme.withAlpha(QsConfig.Theme.tertiary, 0.2) : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: bluetooth.connected ? "󰂯" : "󰂲"
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.titleLarge.size
                            color: bluetooth.connected ? QsConfig.Theme.tertiary : QsConfig.Theme.text
                        }
                    }
                    
                    // Device name and status to the right of icon
                    Text {
                        Layout.fillWidth: true
                        text: bluetooth.connected ? 
                              (bluetooth.deviceName || "Connected") :
                              "Bluetooth Disconnected"
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                        font.weight: Font.Medium
                        color: QsConfig.Theme.text
                        elide: Text.ElideRight
                    }
                    
                    Text {
                        text: "󰅂"
                        font.family: QsConfig.Appearance.typography.iconFamily
                        font.pixelSize: QsConfig.Appearance.typography.titleMedium.size
                        color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.5)
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bluetoothSettingsProc.running = true
                    }
                    
                    onPressed: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
                    onReleased: parent.color = QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.05)
                }
            }
            
            // Volume Control
            Text {
                text: "Volume"
                font.family: QsConfig.Appearance.typography.family
                font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                font.weight: Font.DemiBold
                color: QsConfig.Theme.text
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: QsConfig.Appearance.spacing.m
                
                // Output volume
                RowLayout {
                    Layout.fillWidth: true
                    spacing: QsConfig.Appearance.spacing.m
                    
                    Text {
                        text: audio.muted ? "󰖁" : "󰕾"
                        font.family: QsConfig.Appearance.typography.iconFamily
                        font.pixelSize: QsConfig.Appearance.typography.headlineSmall.size
                        color: QsConfig.Theme.text
                    }
                    
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 150
                        value: audio.percentage
                        
                        onMoved: {
                            audio.setVolume(value / 100)
                        }
                        
                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: parent.availableWidth
                            height: 6
                            radius: height / 2
                            color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)

                            Rectangle {
                                width: parent.parent.visualPosition * parent.width
                                height: parent.height
                                color: QsConfig.Theme.tertiary
                                radius: height / 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: 18
                            height: 18
                            radius: height / 2
                            color: QsConfig.Theme.text
                            border.color: QsConfig.Theme.tertiary
                            border.width: 2
                        }
                    }
                    
                    Text {
                        text: audio.percentage + "%"
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                        font.weight: Font.Medium
                        color: QsConfig.Theme.text
                        Layout.preferredWidth: 45
                    }
                }
            }
            
            // Brightness Control
            Text {
                text: "Brightness"
                font.family: QsConfig.Appearance.typography.family
                font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                font.weight: Font.DemiBold
                color: QsConfig.Theme.text
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: QsConfig.Appearance.spacing.m
                
                Text {
                    text: "󰃠"
                    font.family: QsConfig.Appearance.typography.iconFamily
                    font.pixelSize: QsConfig.Appearance.typography.headlineSmall.size
                    color: QsConfig.Theme.text
                }
                
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: brightness.percentage
                    
                    onMoved: brightness.setBrightness(value / 100)
                    
                    background: Rectangle {
                        x: parent.leftPadding
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        width: parent.availableWidth
                        height: 6
                        radius: height / 2
                        color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)

                        Rectangle {
                            width: parent.parent.visualPosition * parent.width
                            height: parent.height
                            color: QsConfig.Theme.secondary
                            radius: height / 2
                        }
                    }
                    
                    handle: Rectangle {
                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        width: 18
                        height: 18
                        radius: height / 2
                        color: QsConfig.Theme.text
                        border.color: QsConfig.Theme.secondary
                        border.width: 2
                    }
                }
                
                Text {
                    text: brightness.percentage + "%"
                    font.family: QsConfig.Appearance.typography.family
                    font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                    font.weight: Font.Medium
                    color: QsConfig.Theme.text
                    Layout.preferredWidth: 45
                }
            }
        }
    }
}
