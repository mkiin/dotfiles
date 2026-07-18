import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../theme" as QsTheme
import "../../components/containers"

// Audio device selector — 殻(配置/アニメ/クローズ)は FloatingPanel、ここは中身だけ
FloatingPanel {
    id: popupWindow

    panelWidth: 320

    readonly property int rowHeight: 44
    readonly property int cardPadding: 16
    readonly property int headerIconSize: 36
    readonly property int buttonHeight: 36

    // 出力(sink)/入力(source) デバイス。アプリのストリームは除外。
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    function audioIcon(n) {
        const s = ((n?.description ?? "") + " " + (n?.name ?? "")).toLowerCase();
        if (s.includes("headphone") || s.includes("headset"))
            return "󰋋";
        if (s.includes("hdmi") || s.includes("displayport") || s.includes("display"))
            return "󰍹";
        if (s.includes("bluetooth") || s.includes("bluez"))
            return "󰂰";
        return "󰓃";
    }

    // 表示中ノードをトラッキング（state を確実に bind）
    PwObjectTracker {
        objects: [...popupWindow.sinks, ...popupWindow.sources]
    }

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
        readonly property bool isDefault: isOutput ? (node && Pipewire.defaultAudioSink && node.id === Pipewire.defaultAudioSink.id) : (node && Pipewire.defaultAudioSource && node.id === Pipewire.defaultAudioSource.id)

        Layout.fillWidth: true
        Layout.preferredHeight: popupWindow.rowHeight
        radius: QsTheme.Appearance.radius.s
        color: rowArea.containsMouse ? QsTheme.Theme.hover : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: QsTheme.Appearance.anim.durations.fast
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: QsTheme.Appearance.margin.m
            anchors.rightMargin: QsTheme.Appearance.margin.m
            spacing: QsTheme.Appearance.spacing.m

            Text {
                text: row.isOutput ? popupWindow.audioIcon(row.node) : "󰍬"
                font.family: QsTheme.Appearance.typography.iconFamily
                font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                color: row.isDefault ? QsTheme.Theme.accent : QsTheme.Theme.text
            }

            Text {
                Layout.fillWidth: true
                text: row.node ? (row.node.description || row.node.nickname || row.node.name) : ""
                elide: Text.ElideRight
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                font.weight: row.isDefault ? Font.Medium : Font.Normal
                color: row.isDefault ? QsTheme.Theme.accent : QsTheme.Theme.text
            }

            Text {
                visible: row.isDefault
                text: "󰄬"
                font.family: QsTheme.Appearance.typography.iconFamily
                font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                color: QsTheme.Theme.accent
            }
        }

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (row.isOutput)
                    Pipewire.preferredDefaultAudioSink = row.node;
                else
                    Pipewire.preferredDefaultAudioSource = row.node;
            }
        }
    }

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        implicitHeight: contentColumn.implicitHeight + popupWindow.cardPadding * 2
        color: QsTheme.Theme.panel
        radius: QsTheme.Appearance.radius.m
        border.color: QsTheme.Theme.borderFaint
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
            spacing: QsTheme.Appearance.spacing.m

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: QsTheme.Appearance.spacing.m

                Rectangle {
                    width: popupWindow.headerIconSize
                    height: popupWindow.headerIconSize
                    radius: QsTheme.Appearance.radius.s
                    color: Qt.rgba(QsTheme.Theme.accent.r, QsTheme.Theme.accent.g, QsTheme.Theme.accent.b, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: "󰓃"
                        font.family: QsTheme.Appearance.typography.iconFamily
                        font.pixelSize: QsTheme.Appearance.typography.titleMedium.size
                        color: QsTheme.Theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: QsTheme.Appearance.spacing.xs

                    Text {
                        text: "Audio"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                        font.weight: Font.Bold
                        color: QsTheme.Theme.text
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        verticalAlignment: Text.AlignVCenter
                        maximumLineCount: 1
                        text: Pipewire.defaultAudioSink ? (Pipewire.defaultAudioSink.description || Pipewire.defaultAudioSink.name) : "No output device"
                        elide: Text.ElideRight
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                        color: QsTheme.Theme.textMuted
                    }
                }
            }

            // Output section
            Text {
                text: "Output"
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                font.weight: Font.Medium
                color: QsTheme.Theme.textMuted
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: outColumn.implicitHeight + 8
                radius: QsTheme.Appearance.radius.s
                color: QsTheme.Theme.card

                ColumnLayout {
                    id: outColumn
                    anchors.fill: parent
                    anchors.margins: QsTheme.Appearance.spacing.xs
                    spacing: QsTheme.Appearance.spacing.xs

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
                        Layout.margins: QsTheme.Appearance.margin.s
                        horizontalAlignment: Text.AlignHCenter
                        text: "No output devices"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                        color: QsTheme.Theme.textMuted
                    }
                }
            }

            // Input section（入力デバイスがある時だけ）
            Text {
                visible: popupWindow.sources.length > 0
                text: "Input"
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                font.weight: Font.Medium
                color: QsTheme.Theme.textMuted
            }

            Rectangle {
                visible: popupWindow.sources.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: inColumn.implicitHeight + 8
                radius: QsTheme.Appearance.radius.s
                color: QsTheme.Theme.card

                ColumnLayout {
                    id: inColumn
                    anchors.fill: parent
                    anchors.margins: QsTheme.Appearance.spacing.xs
                    spacing: QsTheme.Appearance.spacing.xs

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
                radius: QsTheme.Appearance.radius.s
                color: settingsArea.containsMouse ? QsTheme.Theme.hover : "transparent"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: QsTheme.Appearance.spacing.s

                    Text {
                        text: "󰒓"
                        font.family: QsTheme.Appearance.typography.iconFamily
                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                        color: QsTheme.Theme.textMuted
                    }

                    Text {
                        text: "Sound Settings"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                        color: QsTheme.Theme.textMuted
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
