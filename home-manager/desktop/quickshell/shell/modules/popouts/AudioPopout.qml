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

    readonly property int popoutWidth: 320
    readonly property int rowHeight: 44
    readonly property int cardPadding: 16
    readonly property int headerIconSize: 36
    readonly property int buttonHeight: 36

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
        Layout.preferredHeight: popupWindow.rowHeight
        radius: QsConfig.Appearance.radius.s
        color: rowArea.containsMouse ? QsConfig.Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: QsConfig.Appearance.anim.durations.fast } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: QsConfig.Appearance.margin.m
            anchors.rightMargin: QsConfig.Appearance.margin.m
            spacing: QsConfig.Appearance.spacing.m

            Text {
                text: row.isOutput ? popupWindow.audioIcon(row.node) : "󰍬"
                font.family: QsConfig.Appearance.typography.iconFamily
                font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                color: row.isDefault ? QsConfig.Theme.accent : QsConfig.Theme.text
            }

            Text {
                Layout.fillWidth: true
                text: row.node ? (row.node.description || row.node.nickname || row.node.name) : ""
                elide: Text.ElideRight
                font.family: QsConfig.Appearance.typography.family
                font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                font.weight: row.isDefault ? Font.Medium : Font.Normal
                color: row.isDefault ? QsConfig.Theme.accent : QsConfig.Theme.text
            }

            Text {
                visible: row.isDefault
                text: "󰄬"
                font.family: QsConfig.Appearance.typography.iconFamily
                font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
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
            anchors.topMargin: QsConfig.Appearance.margin.s
            anchors.rightMargin: popupWindow.popupRightMargin
            implicitWidth: popupWindow.popoutWidth
            implicitHeight: contentColumn.implicitHeight + popupWindow.cardPadding * 2
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
                                text: "󰓃"
                                font.family: QsConfig.Appearance.typography.iconFamily
                                font.pixelSize: QsConfig.Appearance.typography.titleMedium.size
                                color: QsConfig.Theme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: QsConfig.Appearance.spacing.xs

                            Text {
                                text: "Audio"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
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
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.labelSmall.size
                                color: QsConfig.Theme.textMuted
                            }
                        }
                    }

                    // Output section
                    Text {
                        text: "Output"
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                        font.weight: Font.Medium
                        color: QsConfig.Theme.textMuted
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: outColumn.implicitHeight + 8
                        radius: QsConfig.Appearance.radius.s
                        color: QsConfig.Theme.card

                        ColumnLayout {
                            id: outColumn
                            anchors.fill: parent
                            anchors.margins: QsConfig.Appearance.spacing.xs
                            spacing: QsConfig.Appearance.spacing.xs

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
                                Layout.margins: QsConfig.Appearance.margin.s
                                horizontalAlignment: Text.AlignHCenter
                                text: "No output devices"
                                font.family: QsConfig.Appearance.typography.family
                                font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                                color: QsConfig.Theme.textMuted
                            }
                        }
                    }

                    // Input section（入力デバイスがある時だけ）
                    Text {
                        visible: popupWindow.sources.length > 0
                        text: "Input"
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                        font.weight: Font.Medium
                        color: QsConfig.Theme.textMuted
                    }

                    Rectangle {
                        visible: popupWindow.sources.length > 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: inColumn.implicitHeight + 8
                        radius: QsConfig.Appearance.radius.s
                        color: QsConfig.Theme.card

                        ColumnLayout {
                            id: inColumn
                            anchors.fill: parent
                            anchors.margins: QsConfig.Appearance.spacing.xs
                            spacing: QsConfig.Appearance.spacing.xs

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
                                text: "Sound Settings"
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
