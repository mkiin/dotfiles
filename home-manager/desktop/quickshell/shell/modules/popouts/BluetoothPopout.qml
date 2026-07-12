import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import "../../services" as QsServices
import "../../config" as QsConfig

// Solid Bluetooth Popup - Matching Control Center style
PanelWindow {
    id: popupWindow

    property bool shouldShow: false

    readonly property int popoutWidth: 320
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
        if (a.connected !== b.connected) return b.connected - a.connected
        if (a.bonded !== b.bonded) return b.bonded - a.bonded
        return a.name.localeCompare(b.name)
    })


    // Settings launcher
    Process {
        id: settingsProcess
        command: ["blueman-manager"]
        onStarted: popupWindow.shouldShow = false
    }

    // waybar の Bluetooth モジュール基準の固定配置（クリック位置に依らず一定）
    property real barBottom: 40       // waybar 下端（モニタ上端から px）。window をこの下に置きバーと被らせない
    property real popupLeftMargin: 8  // 左上角寄せ。8 = waybar 左端と一致（シャドウ切れ防止の最小余白）

    // クリックしたモニター（フォーカス中の出力）に追従
    screen: [...Quickshell.screens].find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    // バー下端より下だけを覆う透明オーバーレイ（枠外クリック検出・バーには被らない）
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    margins {
        top: barBottom
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shouldShow || card.opacity > 0

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: container
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: popupWindow.shouldShow = false

        // 枠外クリックで閉じる（カード背面のバックドロップ）
        MouseArea {
            anchors.fill: parent
            onClicked: popupWindow.shouldShow = false
        }

        // ポップアップ本体（右上アンカー・トリガー付近）
        Item {
            id: card
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: QsConfig.Appearance.margin.s
            anchors.leftMargin: popupWindow.popupLeftMargin
            implicitWidth: popupWindow.popoutWidth
            implicitHeight: contentColumn.implicitHeight + popupWindow.cardPadding * 2
            width: implicitWidth
            height: implicitHeight

            scale: 0.94
            opacity: 0
            transformOrigin: Item.TopLeft

            // カード上のクリックはバックドロップへ伝播させない
            MouseArea { anchors.fill: parent }

            states: State {
                name: "visible"
                when: popupWindow.shouldShow
                PropertyChanges { target: card; opacity: 1; scale: 1.0 }
            }

            transitions: [
                Transition {
                    to: "visible"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: QsConfig.Appearance.anim.durations.normal; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; duration: QsConfig.Appearance.anim.durations.medium; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                    }
                },
                Transition {
                    from: "visible"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: QsConfig.Appearance.anim.durations.fast; easing.type: Easing.InQuad }
                        NumberAnimation { property: "scale"; to: 0.94; duration: QsConfig.Appearance.anim.durations.fast }
                    }
                }
            ]

            // Background with shadow
            Rectangle {
                id: backgroundRect
                anchors.fill: parent
                color: QsConfig.Theme.panel
                radius: QsConfig.Appearance.radius.m
                border.color: QsConfig.Theme.borderFaint
                border.width: 1

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.35)
                    shadowBlur: 1.0
                    shadowVerticalOffset: 6
                }

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: popupWindow.cardPadding
                    spacing: QsConfig.Appearance.spacing.m

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: QsConfig.Appearance.spacing.m

                        Rectangle {
                            width: popupWindow.headerIconSize
                            height: popupWindow.headerIconSize
                            radius: QsConfig.Appearance.radius.s
                            color: Qt.rgba(QsConfig.Theme.accent.r, QsConfig.Theme.accent.g, QsConfig.Theme.accent.b, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: "󰂯"
                                font.family: QsConfig.Appearance.typography.iconFamily
                                font.pixelSize: QsConfig.Appearance.typography.titleMedium.size
                                color: QsConfig.Theme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: QsConfig.Appearance.spacing.xs

                            Text {
                                text: "Bluetooth"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                                font.weight: Font.Bold
                                color: QsConfig.Theme.text
                            }

                            Text {
                                property var connected: devices.filter(d => d.connected)
                                text: connected.length > 0 ? connected[0].name : "No device connected"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                                color: QsConfig.Theme.textMuted
                            }
                        }

                        // Toggle
                        Rectangle {
                            width: 44
                            height: 24
                            radius: height / 2
                            color: adapter?.enabled ? QsConfig.Theme.accent : Qt.rgba(QsConfig.Theme.text.r, QsConfig.Theme.text.g, QsConfig.Theme.text.b, 0.15)

                            Behavior on color { ColorAnimation { duration: QsConfig.Appearance.anim.durations.fast } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: height / 2
                                anchors.verticalCenter: parent.verticalCenter
                                x: adapter?.enabled ? parent.width - width - 3 : 3
                                color: "#ffffff"

                                Behavior on x { NumberAnimation { duration: QsConfig.Appearance.anim.durations.fast; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (adapter) adapter.enabled = !adapter.enabled
                            }
                        }
                    }

                    // Scan button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: popupWindow.buttonHeight
                        radius: QsConfig.Appearance.radius.s
                        color: scanArea.containsMouse ? QsConfig.Theme.cardHigh : QsConfig.Theme.card

                        Behavior on color { ColorAnimation { duration: QsConfig.Appearance.anim.durations.fast } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: QsConfig.Appearance.spacing.s

                            Text {
                                text: adapter?.discovering ? "󰑐" : "󰑓"
                                font.family: QsConfig.Appearance.typography.iconFamily
                                font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                                color: adapter?.discovering ? QsConfig.Theme.accent : QsConfig.Theme.text

                                RotationAnimation on rotation {
                                    running: adapter?.discovering ?? false
                                    from: 0; to: 360; duration: popupWindow.spinDuration; loops: Animation.Infinite
                                }
                            }

                            Text {
                                text: adapter?.discovering ? "Scanning..." : "Scan for devices"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                                font.weight: Font.Medium
                                color: QsConfig.Theme.text
                            }
                        }

                        MouseArea {
                            id: scanArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (adapter) adapter.discovering = !adapter.discovering
                        }
                    }

                    // Device List
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(deviceList.contentHeight + 8, popupWindow.listMaxHeight)
                        radius: QsConfig.Appearance.radius.s
                        color: QsConfig.Theme.card
                        clip: true

                        ListView {
                            id: deviceList
                            anchors.fill: parent
                            anchors.margins: QsConfig.Appearance.spacing.xs
                            spacing: QsConfig.Appearance.spacing.xs
                            model: devices
                            clip: true

                            delegate: Rectangle {
                                id: deviceItem
                                width: deviceList.width
                                height: popupWindow.rowHeight
                                radius: QsConfig.Appearance.radius.s
                                color: itemArea.containsMouse ? QsConfig.Theme.hover : "transparent"

                                required property var modelData
                                property bool isConnected: modelData.connected
                                readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting
                                                          || modelData.state === BluetoothDeviceState.Disconnecting
                                                          || modelData.pairing

                                // Tier1: ペア成立で自動 trust＋接続、停滞ペアはタイムアウトで cancel
                                Connections {
                                    target: deviceItem.modelData
                                    function onPairedChanged() {
                                        if (deviceItem.modelData.paired) {
                                            deviceItem.modelData.trusted = true
                                            deviceItem.modelData.connected = true
                                        }
                                    }
                                }
                                Timer {
                                    id: pairTimer
                                    interval: 30000
                                    onTriggered: if (deviceItem.modelData.pairing) deviceItem.modelData.cancelPair()
                                }

                                Behavior on color { ColorAnimation { duration: QsConfig.Appearance.anim.durations.fast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: QsConfig.Appearance.margin.m
                                    anchors.rightMargin: QsConfig.Appearance.margin.m
                                    spacing: QsConfig.Appearance.spacing.m

                                    // Icon
                                    Text {
                                        text: {
                                            const icon = deviceItem.modelData.icon || ""
                                            if (icon.includes("audio")) return "󰋋"
                                            if (icon.includes("phone")) return "󰄜"
                                            if (icon.includes("computer")) return "󰌢"
                                            if (icon.includes("mouse")) return "󰍽"
                                            if (icon.includes("keyboard")) return "󰌌"
                                            return "󰂯"
                                        }
                                        font.family: QsConfig.Appearance.typography.iconFamily
                                        font.pixelSize: QsConfig.Appearance.typography.titleMedium.size
                                        color: isConnected ? QsConfig.Theme.accent : QsConfig.Theme.text
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: QsConfig.Appearance.spacing.xs

                                        Text {
                                            text: deviceItem.modelData.name
                                            font.family: QsConfig.Appearance.typography.family
                                            font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                                            font.weight: Font.Medium
                                            color: QsConfig.Theme.text
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: {
                                                if (deviceItem.modelData.pairing) return "Pairing..."
                                                if (deviceItem.modelData.state === BluetoothDeviceState.Connecting) return "Connecting..."
                                                if (deviceItem.modelData.state === BluetoothDeviceState.Disconnecting) return "Disconnecting..."
                                                if (isConnected) return "Connected"
                                                if (deviceItem.modelData.bonded) return "Paired"
                                                return "Available"
                                            }
                                            font.family: QsConfig.Appearance.typography.family
                                            font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                                            color: isConnected ? QsConfig.Theme.accent : QsConfig.Theme.textMuted
                                        }
                                    }

                                    // Actions: trust / forget（ペア済みのみ）＋ プライマリ pair/connect/disconnect
                                    RowLayout {
                                        spacing: QsConfig.Appearance.spacing.s

                                        // Trust トグル
                                        Rectangle {
                                            visible: deviceItem.modelData.bonded
                                            Layout.preferredWidth: popupWindow.actionButtonSize
                                            Layout.preferredHeight: popupWindow.actionButtonSize
                                            radius: height / 2
                                            color: trustArea.containsMouse ? QsConfig.Theme.hover : "transparent"
                                            border.width: 1
                                            border.color: deviceItem.modelData.trusted ? QsConfig.Theme.accent : Qt.rgba(QsConfig.Theme.text.r, QsConfig.Theme.text.g, QsConfig.Theme.text.b, 0.15)

                                            Text {
                                                anchors.centerIn: parent
                                                text: deviceItem.modelData.trusted ? "󰕥" : "󰒙"
                                                font.family: QsConfig.Appearance.typography.iconFamily
                                                font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                                                color: deviceItem.modelData.trusted ? QsConfig.Theme.accent : QsConfig.Theme.textMuted
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
                                            color: forgetArea.containsMouse ? QsConfig.Theme.hover : "transparent"
                                            border.width: 1
                                            border.color: Qt.rgba(QsConfig.Theme.text.r, QsConfig.Theme.text.g, QsConfig.Theme.text.b, 0.15)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰆴"
                                                font.family: QsConfig.Appearance.typography.iconFamily
                                                font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                                                color: QsConfig.Theme.textMuted
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
                                            color: actionArea.containsMouse ? Qt.rgba(QsConfig.Theme.accent.r, QsConfig.Theme.accent.g, QsConfig.Theme.accent.b, 0.15) : "transparent"
                                            border.width: 1
                                            border.color: isConnected ? QsConfig.Theme.accent : Qt.rgba(QsConfig.Theme.text.r, QsConfig.Theme.text.g, QsConfig.Theme.text.b, 0.15)

                                            Text {
                                                anchors.centerIn: parent
                                                text: deviceItem.busy ? "󰑓" : isConnected ? "󰌊" : "󰌘"
                                                font.family: QsConfig.Appearance.typography.iconFamily
                                                font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                                                color: isConnected ? QsConfig.Theme.accent : QsConfig.Theme.textMuted

                                                RotationAnimation on rotation {
                                                    running: deviceItem.busy
                                                    from: 0; to: 360; duration: popupWindow.spinDuration; loops: Animation.Infinite
                                                }
                                            }

                                            MouseArea {
                                                id: actionArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    const d = deviceItem.modelData
                                                    if (deviceItem.busy) { if (d.pairing) d.cancelPair(); return }
                                                    if (d.connected) d.connected = false
                                                    else if (d.bonded) { d.trusted = true; d.connected = true }
                                                    else { d.pair(); pairTimer.restart() }
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
                            spacing: QsConfig.Appearance.spacing.s

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "󰂲"
                                font.family: QsConfig.Appearance.typography.iconFamily
                                font.pixelSize: QsConfig.Appearance.typography.headlineLarge.size
                                color: Qt.rgba(QsConfig.Theme.text.r, QsConfig.Theme.text.g, QsConfig.Theme.text.b, 0.2)
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: adapter?.enabled ? "No devices found" : "Bluetooth disabled"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                                color: QsConfig.Theme.textMuted
                            }
                        }
                    }

                    // Settings button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: popupWindow.buttonHeight
                        radius: QsConfig.Appearance.radius.s
                        color: settingsArea.containsMouse ? QsConfig.Theme.hover : "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: QsConfig.Appearance.spacing.s

                            Text {
                                text: "󰒓"
                                font.family: QsConfig.Appearance.typography.iconFamily
                                font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                                color: QsConfig.Theme.textMuted
                            }

                            Text {
                                text: "Bluetooth Settings"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                                color: QsConfig.Theme.textMuted
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
    }
}
