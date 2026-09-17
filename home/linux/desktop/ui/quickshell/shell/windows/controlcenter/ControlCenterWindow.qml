import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../ui" as QsUi
import "../../theme" as QsTheme
import "../../features/audio" as QsAudio
import "../../features/media" as QsMedia
import "../../features/notifications" as QsNotifications
import "." as QsCC

// コントロールセンター。殻(配置/クローズ/面)は PopupCard、ここは中身の組み立てだけ。
QsUi.PopupCard {
    id: popup

    readonly property var audio: QsAudio.Audio

    cardWidth: QsTheme.Appearance.popup.controlCenterWidth

    // 閉じたら既読にする。既読は lastReadAt からの導出なので境界を進めるだけでよい。
    onShouldShowChanged: {
        if (!shouldShow)
            QsNotifications.Notifs.markAllRead();
    }

    Process {
        id: powerProcess
        command: ["wlogout"]
        onStarted: popup.shouldShow = false
    }

    // 開いている間だけ動く分針。プロセス起動なし。
    SystemClock {
        id: clock
        enabled: popup.shouldShow
        precision: SystemClock.Minutes
    }

    // ── ヘッダー: 時刻・日付 + 電源 ──
    RowLayout {
        Layout.fillWidth: true
        spacing: QsTheme.Appearance.spacing.m

        ColumnLayout {
            spacing: 2

            Text {
                text: Qt.formatTime(clock.date, "hh:mm")
                font.family: QsTheme.Appearance.fontFamily
                font.pixelSize: QsTheme.Appearance.fontSize.xl
                font.weight: Font.Bold
                color: QsTheme.Theme.text
            }

            Text {
                text: Qt.formatDate(clock.date, "dddd, MMMM d")
                font.family: QsTheme.Appearance.fontFamily
                font.pixelSize: QsTheme.Appearance.fontSize.s
                color: QsTheme.Theme.textVariant
            }
        }

        Item {
            Layout.fillWidth: true
        }

        QsUi.Button {
            variant: "outline"
            iconOnly: true
            text: "󰐥"
            onClicked: powerProcess.running = true
        }
    }

    QsCC.QuickActions {
        Layout.fillWidth: true
        onRequestClose: popup.shouldShow = false
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: QsTheme.Theme.border
    }

    // ── 音量 ──
    RowLayout {
        Layout.fillWidth: true
        spacing: QsTheme.Appearance.spacing.m

        QsUi.Button {
            variant: "ghost"
            iconOnly: true
            text: popup.audio.muted ? "󰝟" : (popup.audio.percentage > 66 ? "󰕾" : (popup.audio.percentage > 33 ? "󰖀" : "󰕿"))
            onClicked: popup.audio.toggleMute()
        }

        QsUi.Slider {
            id: volumeSlider

            Layout.fillWidth: true
            onMoved: popup.audio.setVolume(value)

            // ドラッグで宣言時の束縛が切れるため、外部変化は Binding で書き戻す
            Binding on value {
                value: popup.audio.volume
                when: !volumeSlider.pressed
                restoreMode: Binding.RestoreNone
            }
        }

        Text {
            Layout.preferredWidth: 40
            text: popup.audio.percentage + "%"
            font.family: QsTheme.Appearance.fontFamily
            font.pixelSize: QsTheme.Appearance.fontSize.s
            font.weight: Font.Medium
            color: QsTheme.Theme.textVariant
            horizontalAlignment: Text.AlignRight
        }
    }

    // ── アプリ別音量（展開トグル） ──
    ColumnLayout {
        id: mixerSection

        property bool expanded: false

        Layout.fillWidth: true
        spacing: QsTheme.Appearance.spacing.s

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: mixerHeader.implicitHeight + QsTheme.Appearance.padding.xs * 2
            radius: QsTheme.Appearance.radius.xs
            color: "transparent"

            RowLayout {
                id: mixerHeader

                anchors.fill: parent
                anchors.leftMargin: QsTheme.Appearance.padding.s
                anchors.rightMargin: QsTheme.Appearance.padding.s
                spacing: QsTheme.Appearance.spacing.s

                Text {
                    Layout.fillWidth: true
                    text: "アプリ音量"
                    font.family: QsTheme.Appearance.fontFamily
                    font.pixelSize: QsTheme.Appearance.fontSize.s
                    font.weight: Font.Medium
                    color: QsTheme.Theme.textVariant
                }

                Text {
                    text: mixerSection.expanded ? "󰅀" : "󰅂"
                    font.family: QsTheme.Appearance.iconFamily
                    font.pixelSize: QsTheme.Appearance.fontSize.m
                    color: QsTheme.Theme.textVariant
                }
            }

            QsUi.StateLayer {
                color: QsTheme.Theme.text
                onClicked: mixerSection.expanded = !mixerSection.expanded
            }
        }

        // 展開アニメ: clip した枠の高さを 0↔内容高 で補間する
        Item {
            Layout.fillWidth: true
            clip: true
            implicitHeight: mixerSection.expanded ? mixer.implicitHeight : 0

            Behavior on implicitHeight {
                QsUi.Anim {
                    speed: "fast"
                }
            }

            ColumnLayout {
                id: mixer

                width: parent.width
                spacing: QsTheme.Appearance.spacing.s

                QsUi.Empty {
                    Layout.fillWidth: true
                    title: "No streams"
                    visible: popup.audio.streams.length === 0
                }

                Repeater {
                    model: popup.audio.streams

                    delegate: RowLayout {
                        id: streamRow

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.leftMargin: QsTheme.Appearance.padding.s
                        Layout.rightMargin: QsTheme.Appearance.padding.s
                        spacing: QsTheme.Appearance.spacing.s

                        QsUi.Button {
                            variant: "ghost"
                            size: "sm"
                            iconOnly: true
                            text: streamRow.modelData.audio.muted ? "󰝟" : "󰕾"
                            onClicked: popup.audio.toggleStreamMute(streamRow.modelData)
                        }

                        Text {
                            Layout.preferredWidth: 120
                            text: popup.audio.streamLabel(streamRow.modelData)
                            font.family: QsTheme.Appearance.fontFamily
                            font.pixelSize: QsTheme.Appearance.fontSize.xs
                            color: QsTheme.Theme.text
                            elide: Text.ElideRight
                        }

                        QsUi.Slider {
                            id: streamSlider

                            Layout.fillWidth: true
                            size: "sm"
                            onMoved: popup.audio.setStreamVolume(streamRow.modelData, value)

                            Binding on value {
                                value: streamRow.modelData.audio.volume
                                when: !streamSlider.pressed
                                restoreMode: Binding.RestoreNone
                            }
                        }
                    }
                }
            }
        }
    }

    QsCC.MediaCard {
        Layout.fillWidth: true
        visible: QsMedia.Players.hasPlayer
    }

    QsCC.NotificationList {
        Layout.fillWidth: true
    }
}
