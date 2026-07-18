import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell.Bluetooth
import Quickshell.Io
import "../theme" as QsTheme
import "../ui"

// Bluetooth device selector — 殻(配置/アニメ/クローズ)は FloatingPanel、ここは中身だけ
FloatingPanel {
    id: popupWindow

    panelWidth: 320

    readonly property int rowHeight: 52
    readonly property int cardPadding: 16
    readonly property int headerIconSize: 36
    readonly property int buttonHeight: 36
    readonly property int actionButtonSize: 26
    readonly property int primaryButtonSize: 28
    readonly property int listMaxHeight: 260
    readonly property int spinDuration: 1000

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: [...Bluetooth.devices.values].sort((a, b) => {
        if (a.connected !== b.connected)
            return b.connected - a.connected;
        if (a.bonded !== b.bonded)
            return b.bonded - a.bonded;
        return a.name.localeCompare(b.name);
    })

    // Settings launcher
    Process {
        id: settingsProcess
        command: ["blueman-manager"]
        onStarted: popupWindow.shouldShow = false
    }

    // Background with shadow
    PopupCard {
        id: backgroundRect
        anchors.fill: parent
        implicitHeight: contentColumn.implicitHeight + popupWindow.cardPadding * 2

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: popupWindow.cardPadding
            spacing: QsTheme.Appearance.spacing.m

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: QsTheme.Appearance.spacing.m

                Rectangle {
                    width: popupWindow.headerIconSize
                    height: popupWindow.headerIconSize
                    radius: QsTheme.Appearance.radius.s
                    color: QsTheme.Theme.primaryContainer

                    Text {
                        anchors.centerIn: parent
                        text: "󰂯"
                        font.family: QsTheme.Appearance.typography.iconFamily
                        font.pixelSize: QsTheme.Appearance.typography.titleMedium.size
                        color: QsTheme.Theme.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: QsTheme.Appearance.spacing.xs

                    Text {
                        text: "Bluetooth"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                        font.weight: Font.Bold
                        color: QsTheme.Theme.text
                    }

                    Text {
                        property var connected: devices.filter(d => d.connected)
                        text: connected.length > 0 ? connected[0].name : "No device connected"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                        color: QsTheme.Theme.textVariant
                    }
                }

                // Toggle
                Rectangle {
                    width: 44
                    height: 24
                    radius: height / 2
                    color: adapter?.enabled ? QsTheme.Theme.primary : QsTheme.Theme.border


                    Rectangle {
                        width: 18
                        height: 18
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: adapter?.enabled ? parent.width - width - 3 : 3
                        color: "#ffffff"

                        Behavior on x {
                            NumberAnimation {
                                duration: QsTheme.Appearance.anim.durations.fast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (adapter)
                            adapter.enabled = !adapter.enabled
                    }
                }
            }

            // Scan button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: popupWindow.buttonHeight
                radius: QsTheme.Appearance.radius.s
                color: scanArea.containsMouse ? QsTheme.Theme.cardHigh : QsTheme.Theme.card


                RowLayout {
                    anchors.centerIn: parent
                    spacing: QsTheme.Appearance.spacing.s

                    Text {
                        text: adapter?.discovering ? "󰑐" : "󰑓"
                        font.family: QsTheme.Appearance.typography.iconFamily
                        font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                        color: adapter?.discovering ? QsTheme.Theme.primary : QsTheme.Theme.text

                        RotationAnimation on rotation {
                            running: adapter?.discovering ?? false
                            from: 0
                            to: 360
                            duration: popupWindow.spinDuration
                            loops: Animation.Infinite
                        }
                    }

                    Text {
                        text: adapter?.discovering ? "Scanning..." : "Scan for devices"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                        font.weight: Font.Medium
                        color: QsTheme.Theme.text
                    }
                }

                MouseArea {
                    id: scanArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (adapter)
                        adapter.discovering = !adapter.discovering
                }
            }

            // Device List
            Rectangle {
                Layout.fillWidth: true
                // 0 件時は contentHeight が 0 になり empty-state が clip されるため最小高さを確保
                Layout.preferredHeight: popupWindow.devices.length === 0 ? popupWindow.rowHeight * 2 : Math.min(deviceList.contentHeight + 8, popupWindow.listMaxHeight)
                radius: QsTheme.Appearance.radius.s
                color: QsTheme.Theme.card
                clip: true

                ListView {
                    id: deviceList
                    anchors.fill: parent
                    anchors.margins: QsTheme.Appearance.spacing.xs
                    spacing: QsTheme.Appearance.spacing.xs
                    model: devices
                    clip: true

                    delegate: Rectangle {
                        id: deviceItem
                        width: deviceList.width
                        height: popupWindow.rowHeight
                        radius: QsTheme.Appearance.radius.s
                        color: itemArea.containsMouse ? QsTheme.Theme.cardHigh : "transparent"

                        required property var modelData
                        property bool isConnected: modelData.connected
                        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting || modelData.pairing

                        // Tier1: ペア成立で自動 trust＋接続、停滞ペアはタイムアウトで cancel
                        Connections {
                            target: deviceItem.modelData
                            function onPairedChanged() {
                                if (deviceItem.modelData.paired) {
                                    deviceItem.modelData.trusted = true;
                                    deviceItem.modelData.connected = true;
                                }
                            }
                        }
                        Timer {
                            id: pairTimer
                            interval: 30000
                            onTriggered: if (deviceItem.modelData.pairing)
                                deviceItem.modelData.cancelPair()
                        }


                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: QsTheme.Appearance.margin.m
                            anchors.rightMargin: QsTheme.Appearance.margin.m
                            spacing: QsTheme.Appearance.spacing.m

                            // Icon
                            Text {
                                text: {
                                    const icon = deviceItem.modelData.icon || "";
                                    if (icon.includes("audio"))
                                        return "󰋋";
                                    if (icon.includes("phone"))
                                        return "󰄜";
                                    if (icon.includes("computer"))
                                        return "󰌢";
                                    if (icon.includes("mouse"))
                                        return "󰍽";
                                    if (icon.includes("keyboard"))
                                        return "󰌌";
                                    return "󰂯";
                                }
                                font.family: QsTheme.Appearance.typography.iconFamily
                                font.pixelSize: QsTheme.Appearance.typography.titleMedium.size
                                color: isConnected ? QsTheme.Theme.primary : QsTheme.Theme.text
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: QsTheme.Appearance.spacing.xs

                                Text {
                                    text: deviceItem.modelData.name
                                    font.family: QsTheme.Appearance.typography.family
                                    font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                                    font.weight: Font.Medium
                                    color: QsTheme.Theme.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: {
                                        if (deviceItem.modelData.pairing)
                                            return "Pairing...";
                                        if (deviceItem.modelData.state === BluetoothDeviceState.Connecting)
                                            return "Connecting...";
                                        if (deviceItem.modelData.state === BluetoothDeviceState.Disconnecting)
                                            return "Disconnecting...";
                                        if (isConnected)
                                            return "Connected";
                                        if (deviceItem.modelData.bonded)
                                            return "Paired";
                                        return "Available";
                                    }
                                    font.family: QsTheme.Appearance.typography.family
                                    font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                                    color: isConnected ? QsTheme.Theme.primary : QsTheme.Theme.textVariant
                                }
                            }

                            // Actions: trust / forget（ペア済みのみ）＋ プライマリ pair/connect/disconnect
                            RowLayout {
                                spacing: QsTheme.Appearance.spacing.s

                                // Trust トグル
                                Rectangle {
                                    visible: deviceItem.modelData.bonded
                                    Layout.preferredWidth: popupWindow.actionButtonSize
                                    Layout.preferredHeight: popupWindow.actionButtonSize
                                    radius: height / 2
                                    color: trustArea.containsMouse ? QsTheme.Theme.cardHigh : "transparent"
                                    border.width: 1
                                    border.color: deviceItem.modelData.trusted ? QsTheme.Theme.primary : QsTheme.Theme.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: deviceItem.modelData.trusted ? "󰕥" : "󰒙"
                                        font.family: QsTheme.Appearance.typography.iconFamily
                                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                                        color: deviceItem.modelData.trusted ? QsTheme.Theme.primary : QsTheme.Theme.textVariant
                                    }

                                    MouseArea {
                                        id: trustArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: deviceItem.modelData.trusted = !deviceItem.modelData.trusted
                                    }
                                }

                                // Forget
                                Rectangle {
                                    visible: deviceItem.modelData.bonded
                                    Layout.preferredWidth: popupWindow.actionButtonSize
                                    Layout.preferredHeight: popupWindow.actionButtonSize
                                    radius: height / 2
                                    color: forgetArea.containsMouse ? QsTheme.Theme.cardHigh : "transparent"
                                    border.width: 1
                                    border.color: QsTheme.Theme.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰆴"
                                        font.family: QsTheme.Appearance.typography.iconFamily
                                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                                        color: QsTheme.Theme.textVariant
                                    }

                                    MouseArea {
                                        id: forgetArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: deviceItem.modelData.forget()
                                    }
                                }

                                // プライマリ: pair / connect / disconnect /（busy中タップで cancelPair）
                                Rectangle {
                                    Layout.preferredWidth: popupWindow.primaryButtonSize
                                    Layout.preferredHeight: popupWindow.primaryButtonSize
                                    radius: height / 2
                                    color: actionArea.containsMouse ? QsTheme.Theme.primaryContainer : "transparent"
                                    border.width: 1
                                    border.color: isConnected ? QsTheme.Theme.primary : QsTheme.Theme.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: deviceItem.busy ? "󰑓" : isConnected ? "󰌊" : "󰌘"
                                        font.family: QsTheme.Appearance.typography.iconFamily
                                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                                        color: isConnected ? QsTheme.Theme.primary : QsTheme.Theme.textVariant

                                        RotationAnimation on rotation {
                                            running: deviceItem.busy
                                            from: 0
                                            to: 360
                                            duration: popupWindow.spinDuration
                                            loops: Animation.Infinite
                                        }
                                    }

                                    MouseArea {
                                        id: actionArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const d = deviceItem.modelData;
                                            if (deviceItem.busy) {
                                                if (d.pairing)
                                                    d.cancelPair();
                                                return;
                                            }
                                            if (d.connected)
                                                d.connected = false;
                                            else if (d.bonded) {
                                                d.trusted = true;
                                                d.connected = true;
                                            } else {
                                                d.pair();
                                                pairTimer.restart();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            z: -1
                        }
                    }
                }

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: devices.length === 0
                    spacing: QsTheme.Appearance.spacing.s

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰂲"
                        font.family: QsTheme.Appearance.typography.iconFamily
                        font.pixelSize: QsTheme.Appearance.typography.headlineLarge.size
                        color: QsTheme.Theme.border
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: !adapter?.enabled ? "Bluetooth disabled" : (adapter?.discovering ? "Scanning..." : "No devices found")
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                        color: QsTheme.Theme.textVariant
                    }
                }
            }

            // Settings button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: popupWindow.buttonHeight
                radius: QsTheme.Appearance.radius.s
                color: settingsArea.containsMouse ? QsTheme.Theme.cardHigh : "transparent"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: QsTheme.Appearance.spacing.s

                    Text {
                        text: "󰒓"
                        font.family: QsTheme.Appearance.typography.iconFamily
                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                        color: QsTheme.Theme.textVariant
                    }

                    Text {
                        text: "Bluetooth Settings"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                        color: QsTheme.Theme.textVariant
                    }
                }

                MouseArea {
                    id: settingsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsProcess.running = true
                }
            }
        }
    }
}
