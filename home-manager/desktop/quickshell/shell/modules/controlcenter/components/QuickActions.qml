import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../ui"
import "../../../theme" as QsTheme
import "../../../services" as QsServices

// Control Center 上部のクイック操作。データ(tiles)と見た目(delegate)を分けて 1 箇所に閉じる。
// tiles を JS 配列ではなく QtObject の配列にしているのは、配列自体を定数に保つため。
// JS 配列だと依存が変わるたび配列全体が再評価されて delegate が作り直され、
// 色遷移アニメとホバー状態が毎回リセットされる。
GridLayout {
    id: root

    // タイルを押したときにパネルを閉じる必要があるものがあるため、窓側から受け取る
    signal requestClose

    readonly property var screenshot: QsServices.Screenshot

    readonly property list<QtObject> tiles: [
        QtObject {
            readonly property string glyph: "󰖩"
            readonly property string label: "Wi-Fi"
            readonly property string subLabel: QsServices.Network.connected ? QsServices.Network.ssid : "Disconnected"
            readonly property bool on: QsServices.Network.wifiEnabled
            readonly property color accent: QsTheme.Theme.primary
            readonly property color onAccent: QsTheme.Theme.onPrimary
            readonly property bool available: true
            function activate() {
                QsServices.Network.toggleWifi();
            }
        },
        QtObject {
            readonly property string glyph: "󰂯"
            readonly property string label: "Bluetooth"
            readonly property string subLabel: QsServices.Bluetooth.powered ? "On" : "Off"
            readonly property bool on: QsServices.Bluetooth.powered
            readonly property color accent: QsTheme.Theme.primary
            readonly property color onAccent: QsTheme.Theme.onPrimary
            readonly property bool available: true
            function activate() {
                QsServices.Bluetooth.togglePower();
            }
        },
        QtObject {
            readonly property string glyph: "󰔎"
            readonly property string label: "Do Not Disturb"
            readonly property string subLabel: QsServices.Notifs.dnd ? "On" : "Off"
            readonly property bool on: QsServices.Notifs.dnd
            readonly property color accent: QsTheme.Theme.primary
            readonly property color onAccent: QsTheme.Theme.onPrimary
            readonly property bool available: true
            function activate() {
                QsServices.Notifs.toggleDnd();
            }
        },
        QtObject {
            readonly property string glyph: QsServices.IdleInhibitor.inhibited ? "󰈈" : "󰈉"
            readonly property string label: "Caffeine"
            readonly property string subLabel: QsServices.IdleInhibitor.inhibited ? "Active" : "Off"
            readonly property bool on: QsServices.IdleInhibitor.inhibited
            readonly property color accent: QsTheme.Theme.info
            readonly property color onAccent: QsTheme.Theme.onPrimary
            readonly property bool available: true
            function activate() {
                QsServices.IdleInhibitor.inhibited = !QsServices.IdleInhibitor.inhibited;
            }
        },
        QtObject {
            readonly property string glyph: "󰹑"
            readonly property string label: "Screenshot"
            readonly property string subLabel: "Region / Window / Output"
            readonly property bool on: false
            readonly property color accent: QsTheme.Theme.secondary
            readonly property color onAccent: QsTheme.Theme.onSecondary
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
            readonly property color onAccent: QsTheme.Theme.onError
            readonly property bool available: root.screenshot.recorderAvailable
            function activate() {
                if (root.screenshot.isRecording)
                    root.screenshot.stopRecording();
                else
                    root.screenshot.startRecording();
            }
        }
    ]

    columns: 2
    columnSpacing: QsTheme.Appearance.spacing.m
    rowSpacing: QsTheme.Appearance.spacing.m

    Repeater {
        model: root.tiles

        delegate: Button {
            id: tile

            required property QtObject modelData

            readonly property color onAccent: tile.modelData.onAccent
            readonly property color fg: tile.modelData.on ? tile.onAccent : QsTheme.Theme.text

            Layout.fillWidth: true
            Layout.preferredHeight: 72

            enabled: tile.modelData.available
            opacity: enabled ? 1.0 : 0.5

            scale: tile.pressed ? 0.98 : tile.hovered ? QsTheme.Appearance.anim.hoverScale : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: QsTheme.Appearance.anim.durations.short2
                    easing.bezierCurve: QsTheme.Appearance.anim.curves.springGentle
                }
            }

            onClicked: tile.modelData.activate()

            background: Rectangle {
                radius: QsTheme.Appearance.radius.l
                color: tile.modelData.on ? tile.modelData.accent : QsTheme.Theme.card
                border.width: 1
                border.color: tile.modelData.on ? "transparent" : QsTheme.Theme.border
                clip: true

                Behavior on color {
                    ColorAnimation {
                        duration: QsTheme.Appearance.anim.durations.medium2
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: QsTheme.Appearance.anim.durations.short4
                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                    }
                }

                // ホバーの明度差。色に alpha を混ぜず、面を重ねて opacity で出す
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: tile.fg
                    opacity: tile.hovered && !tile.pressed ? 0.08 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: QsTheme.Appearance.anim.durations.short3
                            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                        }
                    }
                }
            }

            contentItem: RowLayout {
                spacing: QsTheme.Appearance.spacing.l

                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: tile.fg
                        opacity: tile.modelData.on ? 0.16 : 0.10
                    }

                    Text {
                        anchors.centerIn: parent
                        text: tile.modelData.glyph
                        font: QsTheme.Appearance.font.iconLarge
                        color: tile.fg

                        Behavior on color {
                            ColorAnimation {
                                duration: QsTheme.Appearance.anim.durations.short4
                                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: QsTheme.Appearance.spacing.xs

                    Text {
                        Layout.fillWidth: true
                        text: tile.modelData.label
                        font: QsTheme.Appearance.font.bodyStrong
                        color: tile.fg
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation {
                                duration: QsTheme.Appearance.anim.durations.short4
                                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: tile.modelData.subLabel
                        font: QsTheme.Appearance.font.label
                        color: tile.fg
                        opacity: 0.7
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }
        }
    }
}
