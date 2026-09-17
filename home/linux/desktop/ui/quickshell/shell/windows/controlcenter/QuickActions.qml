import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../ui" as QsUi
import "../../theme" as QsTheme
import "../../features/bluetooth" as QsBluetooth
import "../../features/network" as QsNetwork
import "../../features/notifications" as QsNotifications
import "../../features/power" as QsPower
import "../../features/screenshot" as QsScreenshot

// CC 上部のクイック操作。データ(tiles)と見た目(delegate)を分けて 1 箇所に閉じる。
// tiles を JS 配列ではなく QtObject の配列にしているのは、配列自体を定数に保つため。
// JS 配列だと依存が変わるたび配列全体が再評価されて delegate が作り直され、
// ホバー状態が毎回リセットされる。
GridLayout {
    id: root

    // タイルによってはパネルを閉じる必要があるため、閉じるかは窓側に委ねる
    signal requestClose

    readonly property var screenshot: QsScreenshot.Screenshot

    readonly property list<QtObject> tiles: [
        QtObject {
            readonly property string glyph: "󰖩"
            readonly property string label: "Wi-Fi"
            readonly property string subLabel: QsNetwork.Network.connected ? QsNetwork.Network.ssid : "Disconnected"
            readonly property bool on: QsNetwork.Network.wifiEnabled
            readonly property color accent: QsTheme.Theme.primary
            readonly property color accentText: QsTheme.Theme._onPrimary
            readonly property bool available: true
            function activate() {
                QsNetwork.Network.toggleWifi();
            }
        },
        QtObject {
            readonly property string glyph: "󰂯"
            readonly property string label: "Bluetooth"
            readonly property string subLabel: QsBluetooth.Bluetooth.powered ? "On" : "Off"
            readonly property bool on: QsBluetooth.Bluetooth.powered
            readonly property color accent: QsTheme.Theme.primary
            readonly property color accentText: QsTheme.Theme._onPrimary
            readonly property bool available: true
            function activate() {
                QsBluetooth.Bluetooth.togglePower();
            }
        },
        QtObject {
            readonly property string glyph: "󰔎"
            readonly property string label: "Do Not Disturb"
            readonly property string subLabel: QsNotifications.Notifs.dnd ? "On" : "Off"
            readonly property bool on: QsNotifications.Notifs.dnd
            readonly property color accent: QsTheme.Theme.primary
            readonly property color accentText: QsTheme.Theme._onPrimary
            readonly property bool available: true
            function activate() {
                QsNotifications.Notifs.toggleDnd();
            }
        },
        QtObject {
            readonly property string glyph: QsPower.IdleInhibitor.inhibited ? "󰈈" : "󰈉"
            readonly property string label: "Caffeine"
            readonly property string subLabel: QsPower.IdleInhibitor.inhibited ? "Active" : "Off"
            readonly property bool on: QsPower.IdleInhibitor.inhibited
            readonly property color accent: QsTheme.Theme.tertiary
            readonly property color accentText: QsTheme.Theme._onTertiary
            readonly property bool available: true
            function activate() {
                QsPower.IdleInhibitor.toggle();
            }
        },
        QtObject {
            readonly property string glyph: "󰹑"
            readonly property string label: "Screenshot"
            readonly property string subLabel: "Region / Window / Output"
            readonly property bool on: false
            readonly property color accent: QsTheme.Theme.secondary
            readonly property color accentText: QsTheme.Theme._onSecondary
            readonly property bool available: true
            function activate() {
                root.requestClose();
                root.screenshot.openMenu();
            }
        },
        QtObject {
            readonly property string glyph: root.screenshot.isRecording ? "󰛿" : "󰻃"
            readonly property string label: root.screenshot.isRecording ? "Stop Recording" : "Record Screen"
            readonly property string subLabel: !root.screenshot.recorderAvailable ? "Install gpu-screen-recorder" : (root.screenshot.isRecording ? "Recording in progress" : "Start recording")
            readonly property bool on: root.screenshot.isRecording
            readonly property color accent: QsTheme.Theme.error
            readonly property color accentText: QsTheme.Theme._onError
            readonly property bool available: root.screenshot.recorderAvailable
            function activate() {
                root.screenshot.toggleRecording();
            }
        }
    ]

    columns: 2
    columnSpacing: QsTheme.Appearance.spacing.m
    rowSpacing: QsTheme.Appearance.spacing.m

    Repeater {
        model: root.tiles

        delegate: Rectangle {
            id: tile

            required property QtObject modelData

            readonly property color fg: tile.modelData.on ? tile.modelData.accentText : QsTheme.Theme.text

            Layout.fillWidth: true
            Layout.preferredHeight: QsTheme.Appearance.popup.tileHeight

            color: tile.modelData.on ? tile.modelData.accent : QsTheme.Theme.card
            radius: QsTheme.Appearance.radius.m
            border.width: tile.modelData.on ? 0 : 1
            border.color: QsTheme.Theme.border
            opacity: tile.modelData.available ? 1 : 0.5

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: QsTheme.Appearance.padding.m
                anchors.rightMargin: QsTheme.Appearance.padding.m
                spacing: QsTheme.Appearance.spacing.m

                Item {
                    Layout.preferredWidth: QsTheme.Appearance.size.headerIcon
                    Layout.preferredHeight: QsTheme.Appearance.size.headerIcon

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: tile.fg
                        opacity: tile.modelData.on ? 0.16 : 0.1
                    }

                    Text {
                        anchors.centerIn: parent
                        text: tile.modelData.glyph
                        font.family: QsTheme.Appearance.iconFamily
                        font.pixelSize: QsTheme.Appearance.fontSize.l
                        color: tile.fg
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: tile.modelData.label
                        font.family: QsTheme.Appearance.fontFamily
                        font.pixelSize: QsTheme.Appearance.fontSize.s
                        font.weight: Font.DemiBold
                        color: tile.fg
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: tile.modelData.subLabel
                        font.family: QsTheme.Appearance.fontFamily
                        font.pixelSize: QsTheme.Appearance.fontSize.xs
                        color: tile.fg
                        opacity: 0.7
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }

            QsUi.StateLayer {
                color: tile.fg
                enabled: tile.modelData.available
                onClicked: tile.modelData.activate()
            }
        }
    }
}
