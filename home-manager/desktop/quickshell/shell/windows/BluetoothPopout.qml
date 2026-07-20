import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell.Io
import "../ui" as QsUi
import "../theme" as QsTheme
import "../features/bluetooth" as QsBluetooth

// waybar の Bluetooth アイコンから開くデバイス一覧。
QsUi.PopupCard {
    id: popup

    readonly property var bluetooth: QsBluetooth.Bluetooth
    readonly property int connectedCount: popup.bluetooth.connectedDevices.length

    cardWidth: QsTheme.Appearance.popup.bluetoothWidth

    Process {
        id: settingsProcess
        command: ["blueman-manager"]
        onStarted: popup.shouldShow = false
    }

    // ── ヘッダー ──
        RowLayout {
            Layout.fillWidth: true
            spacing: QsTheme.Appearance.spacing.m

            Rectangle {
                Layout.preferredWidth: QsTheme.Appearance.size.headerIcon
                Layout.preferredHeight: QsTheme.Appearance.size.headerIcon
                radius: QsTheme.Appearance.radius.s
                color: QsTheme.Theme.primaryContainer

                Text {
                    anchors.centerIn: parent
                    text: "󰂯"
                    font.family: QsTheme.Appearance.iconFamily
                    font.pixelSize: QsTheme.Appearance.fontSize.l
                    color: QsTheme.Theme._onPrimaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Bluetooth"
                    font.family: QsTheme.Appearance.fontFamily
                    font.pixelSize: QsTheme.Appearance.fontSize.l
                    font.weight: Font.DemiBold
                    color: QsTheme.Theme.text
                }

                Text {
                    Layout.fillWidth: true
                    text: popup.connectedCount > 0 ? popup.connectedCount + " connected" : "No device connected"
                    font.family: QsTheme.Appearance.fontFamily
                    font.pixelSize: QsTheme.Appearance.fontSize.xs
                    color: QsTheme.Theme.textVariant
                    elide: Text.ElideRight
                }
            }

            QsUi.Switch {
                Layout.alignment: Qt.AlignVCenter
                checked: popup.bluetooth.powered
                onClicked: popup.bluetooth.togglePower()
            }
        }

        // ── 探索 ──
        // TODO: 探索中はアイコンを回転させる。Button に回転を持たせるか、
        // ここで contentItem を差し替えるかは未決。
        QsUi.Button {
            Layout.fillWidth: true
            text: "󰑐  Scan"
            variant: "outline"
            size: "sm"
            enabled: popup.bluetooth.powered
            onClicked: popup.bluetooth.toggleScan()
        }

        // ── デバイス一覧 ──
        QsUi.Card {
            Layout.fillWidth: true
            size: "sm"

            content: ColumnLayout {
                width: parent.width
                spacing: 2

                QsUi.Empty {
                    Layout.fillWidth: true
                    variant: "icon"
                    icon: "󰂲"
                    title: "No devices found"
                    visible: popup.bluetooth.devices.length === 0
                }

                Repeater {
                    model: popup.bluetooth.devices

                    delegate: QsUi.Item {
                        id: row

                        required property var modelData

                        readonly property bool busy: row.modelData.pairing

                        Layout.fillWidth: true
                        size: "sm"
                        title: row.modelData.name
                        highlighted: row.modelData.connected
                        onClicked: popup.bluetooth.toggleDevice(row.modelData)

                        media: Text {
                            text: "󰂱"
                            font.family: QsTheme.Appearance.iconFamily
                            font.pixelSize: QsTheme.Appearance.fontSize.l
                            color: row.modelData.connected ? QsTheme.Theme.primary : QsTheme.Theme.textVariant
                        }

                        actions: RowLayout {
                            spacing: QsTheme.Appearance.spacing.xs

                            QsUi.Button {
                                text: "󰒃"
                                iconOnly: true
                                size: "sm"
                                variant: "ghost"
                                visible: row.modelData.bonded
                                onClicked: popup.bluetooth.setTrusted(row.modelData, !row.modelData.trusted)
                            }

                            QsUi.Button {
                                text: "󰆴"
                                iconOnly: true
                                size: "sm"
                                variant: "ghost"
                                visible: row.modelData.bonded
                                onClicked: popup.bluetooth.forget(row.modelData)
                            }

                            // pair / connect / disconnect を担う。処理中は押すと中断。
                            QsUi.Button {
                                text: row.busy ? "󰑓" : (row.modelData.connected ? "󰌊" : "󰌘")
                                iconOnly: true
                                size: "sm"
                                variant: row.modelData.connected ? "default" : "outline"
                                onClicked: popup.bluetooth.toggleDevice(row.modelData)
                            }
                        }
                    }
                }
            }
        }

        // ── 設定 ──
        QsUi.Button {
            Layout.fillWidth: true
            text: "󰒓  Bluetooth Settings"
            variant: "outline"
            size: "sm"
            onClicked: settingsProcess.running = true
        }
}
