import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell.Io
import "../ui" as QsUi
import "../theme" as QsTheme
import "../features/audio" as QsAudio

// waybar のオーディオアイコンから開くデバイス選択。
QsUi.PopupCard {
    id: popup

    readonly property var audio: QsAudio.Audio

    cardWidth: QsTheme.Appearance.popup.audioWidth

    Process {
        id: settingsProcess
        command: ["pwvucontrol"]
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
                text: "󰓃"
                font.family: QsTheme.Appearance.iconFamily
                font.pixelSize: QsTheme.Appearance.fontSize.l
                color: QsTheme.Theme._onPrimaryContainer
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Audio"
                font.family: QsTheme.Appearance.fontFamily
                font.pixelSize: QsTheme.Appearance.fontSize.l
                font.weight: Font.DemiBold
                color: QsTheme.Theme.text
            }

            Text {
                Layout.fillWidth: true
                text: popup.audio.labelFor(popup.audio.sink) || "No output device"
                font.family: QsTheme.Appearance.fontFamily
                font.pixelSize: QsTheme.Appearance.fontSize.xs
                color: QsTheme.Theme.textVariant
                elide: Text.ElideRight
            }
        }
    }

    // ── 出力 ──
    Text {
        Layout.fillWidth: true
        text: "Output"
        font.family: QsTheme.Appearance.fontFamily
        font.pixelSize: QsTheme.Appearance.fontSize.s
        font.weight: Font.Medium
        color: QsTheme.Theme.textVariant
    }

    QsUi.Card {
        Layout.fillWidth: true
        size: "sm"

        content: ColumnLayout {
            width: parent.width
            spacing: 2

            QsUi.Empty {
                Layout.fillWidth: true
                variant: "icon"
                icon: "󰓃"
                title: "No output devices"
                visible: popup.audio.sinks.length === 0
            }

            Repeater {
                model: popup.audio.sinks

                delegate: QsUi.Item {
                    id: sinkRow

                    required property var modelData

                    Layout.fillWidth: true
                    size: "sm"
                    title: popup.audio.labelFor(sinkRow.modelData)
                    highlighted: sinkRow.modelData === popup.audio.sink
                    onClicked: popup.audio.setDefaultSink(sinkRow.modelData)

                    media: Text {
                        text: popup.audio.iconFor(sinkRow.modelData)
                        font.family: QsTheme.Appearance.iconFamily
                        font.pixelSize: QsTheme.Appearance.fontSize.l
                        color: sinkRow.highlighted ? QsTheme.Theme.primary : QsTheme.Theme.textVariant
                    }

                    actions: Text {
                        text: "󰄬"
                        font.family: QsTheme.Appearance.iconFamily
                        font.pixelSize: QsTheme.Appearance.fontSize.l
                        color: QsTheme.Theme.primary
                        visible: sinkRow.highlighted
                    }
                }
            }
        }
    }

    // ── 入力 ──
    Text {
        Layout.fillWidth: true
        text: "Input"
        font.family: QsTheme.Appearance.fontFamily
        font.pixelSize: QsTheme.Appearance.fontSize.s
        font.weight: Font.Medium
        color: QsTheme.Theme.textVariant
        visible: popup.audio.sources.length > 0
    }

    QsUi.Card {
        Layout.fillWidth: true
        size: "sm"
        visible: popup.audio.sources.length > 0

        content: ColumnLayout {
            width: parent.width
            spacing: 2

            Repeater {
                model: popup.audio.sources

                delegate: QsUi.Item {
                    id: sourceRow

                    required property var modelData

                    Layout.fillWidth: true
                    size: "sm"
                    title: popup.audio.labelFor(sourceRow.modelData)
                    highlighted: sourceRow.modelData === popup.audio.source
                    onClicked: popup.audio.setDefaultSource(sourceRow.modelData)

                    media: Text {
                        text: "󰍬"
                        font.family: QsTheme.Appearance.iconFamily
                        font.pixelSize: QsTheme.Appearance.fontSize.l
                        color: sourceRow.highlighted ? QsTheme.Theme.primary : QsTheme.Theme.textVariant
                    }

                    actions: Text {
                        text: "󰄬"
                        font.family: QsTheme.Appearance.iconFamily
                        font.pixelSize: QsTheme.Appearance.fontSize.l
                        color: QsTheme.Theme.primary
                        visible: sourceRow.highlighted
                    }
                }
            }
        }
    }

    // ── 設定 ──
    QsUi.Button {
        Layout.fillWidth: true
        text: "󰒓  Sound Settings"
        variant: "outline"
        size: "sm"
        onClicked: settingsProcess.running = true
    }
}
