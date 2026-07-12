import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../services" as QsServices
import "../../config" as QsConfig

// Audio device selector — Bluetooth ポップアップと同じ作り
PanelWindow {
    id: popupWindow

    property bool shouldShow: false

    // 出力(sink)/入力(source) デバイス。アプリのストリームは除外。
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    function audioIcon(n) {
        const s = ((n?.description ?? "") + " " + (n?.name ?? "")).toLowerCase()
        if (s.includes("headphone") || s.includes("headset")) return "󰋋"
        if (s.includes("hdmi") || s.includes("displayport") || s.includes("display")) return "󰍹"
        if (s.includes("bluetooth") || s.includes("bluez")) return "󰂰"
        return "󰓃"
    }


    // 表示中ノードをトラッキング（state を確実に bind）
    PwObjectTracker { objects: [...popupWindow.sinks, ...popupWindow.sources] }

    // Sound settings launcher
    Process {
        id: settingsProcess
        command: ["pwvucontrol"]
        onStarted: popupWindow.shouldShow = false
    }

    // 1行ぶんのデバイス行（出力/入力で共用）
    component DeviceRow: Rectangle {
        id: row
        property var node
        property bool isOutput: false
        readonly property bool isDefault: isOutput
            ? (node && Pipewire.defaultAudioSink && node.id === Pipewire.defaultAudioSink.id)
            : (node && Pipewire.defaultAudioSource && node.id === Pipewire.defaultAudioSource.id)

        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: 10
        color: rowArea.containsMouse ? QsConfig.Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 80 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
                text: row.isOutput ? popupWindow.audioIcon(row.node) : "󰍬"
                font.family: "Material Design Icons"
                font.pixelSize: 16
                color: row.isDefault ? QsConfig.Theme.accent : QsConfig.Theme.text
            }

            Text {
                Layout.fillWidth: true
                text: row.node ? (row.node.description || row.node.nickname || row.node.name) : ""
                elide: Text.ElideRight
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: row.isDefault ? Font.Medium : Font.Normal
                color: row.isDefault ? QsConfig.Theme.accent : QsConfig.Theme.text
            }

            Text {
                visible: row.isDefault
                text: "󰄬"
                font.family: "Material Design Icons"
                font.pixelSize: 14
                color: QsConfig.Theme.accent
            }
        }

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (row.isOutput) Pipewire.preferredDefaultAudioSink = row.node
                else Pipewire.preferredDefaultAudioSource = row.node
            }
        }
    }

    // waybar の audio モジュール基準の固定配置（audio は右側なので右上固定）
    property real barBottom: 40
    property real popupRightMargin: 8  // 8 = waybar 右端と一致

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

        // 枠外クリックで閉じる
        MouseArea {
            anchors.fill: parent
            onClicked: popupWindow.shouldShow = false
        }

        Item {
            id: card
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.rightMargin: popupWindow.popupRightMargin
            implicitWidth: 320
            implicitHeight: contentColumn.implicitHeight + 32
            width: implicitWidth
            height: implicitHeight

            scale: 0.94
            opacity: 0
            transformOrigin: Item.TopRight

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
                        NumberAnimation { property: "opacity"; duration: 180; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                    }
                },
                Transition {
                    from: "visible"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: 120; easing.type: Easing.InQuad }
                        NumberAnimation { property: "scale"; to: 0.94; duration: 120 }
                    }
                }
            ]

            Rectangle {
                id: backgroundRect
                anchors.fill: parent
                color: QsConfig.Theme.panel
                radius: 16
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
                    anchors.margins: 16
                    spacing: 12

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 12
                            color: Qt.rgba(QsConfig.Theme.accent.r, QsConfig.Theme.accent.g, QsConfig.Theme.accent.b, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: "󰓃"
                                font.family: "Material Design Icons"
                                font.pixelSize: 18
                                color: QsConfig.Theme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Audio"
                                font.family: "Inter"
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: QsConfig.Theme.text
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 16
                                verticalAlignment: Text.AlignVCenter
                                maximumLineCount: 1
                                text: Pipewire.defaultAudioSink
                                    ? (Pipewire.defaultAudioSink.description || Pipewire.defaultAudioSink.name)
                                    : "No output device"
                                elide: Text.ElideRight
                                font.family: "Inter"
                                font.pixelSize: 11
                                color: QsConfig.Theme.textMuted
                            }
                        }
                    }

                    // Output section
                    Text {
                        text: "Output"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: QsConfig.Theme.textMuted
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: outColumn.implicitHeight + 8
                        radius: 12
                        color: QsConfig.Theme.card

                        ColumnLayout {
                            id: outColumn
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2

                            Repeater {
                                model: popupWindow.sinks
                                delegate: DeviceRow {
                                    required property var modelData
                                    node: modelData
                                    isOutput: true
                                }
                            }

                            Text {
                                visible: popupWindow.sinks.length === 0
                                Layout.fillWidth: true
                                Layout.margins: 8
                                horizontalAlignment: Text.AlignHCenter
                                text: "No output devices"
                                font.family: "Inter"
                                font.pixelSize: 12
                                color: QsConfig.Theme.textMuted
                            }
                        }
                    }

                    // Input section（入力デバイスがある時だけ）
                    Text {
                        visible: popupWindow.sources.length > 0
                        text: "Input"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: QsConfig.Theme.textMuted
                    }

                    Rectangle {
                        visible: popupWindow.sources.length > 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: inColumn.implicitHeight + 8
                        radius: 12
                        color: QsConfig.Theme.card

                        ColumnLayout {
                            id: inColumn
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2

                            Repeater {
                                model: popupWindow.sources
                                delegate: DeviceRow {
                                    required property var modelData
                                    node: modelData
                                    isOutput: false
                                }
                            }
                        }
                    }

                    // Settings button → pwvucontrol
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 10
                        color: settingsArea.containsMouse ? QsConfig.Theme.hover : "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "󰒓"
                                font.family: "Material Design Icons"
                                font.pixelSize: 14
                                color: QsConfig.Theme.textMuted
                            }

                            Text {
                                text: "Sound Settings"
                                font.family: "Inter"
                                font.pixelSize: 12
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
