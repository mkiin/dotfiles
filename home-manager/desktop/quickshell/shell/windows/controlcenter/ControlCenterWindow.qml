import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell.Io
import "../../theme" as QsTheme
import "../../features/audio" as QsAudio
import "../../features/audio/components" as QsAudioUi
import "../../features/bluetooth" as QsBluetooth
import "../../features/media" as QsMedia
import "../../features/media/components" as QsMediaUi
import "../../features/network" as QsNetwork
import "../../features/notifications" as QsNotifications
import "../../features/notifications/components" as QsNotificationsUi
import "../../features/power" as QsPower
import "../../features/screenshot" as QsScreenshot
import "../../utils" as QsUtils
import "../../config" as QsConfig
import "../../ui"
import "." as QsCC

// 通知センター — 殻(配置/アニメ/クローズ/面)は PopupCard、ここは中身だけ
PopupCard {
    id: root

    cardWidth: 420
    padding: QsTheme.Appearance.margin.l
    shadowOpacity: 0.18
    shadowBlur: 0.4
    shadowOffsetY: 4

    // Services
    readonly property var logger: QsUtils.Logger
    readonly property var config: QsConfig.Config
    readonly property var network: QsNetwork.Network
    readonly property var bluetooth: QsBluetooth.Bluetooth
    readonly property var audio: QsAudio.Audio
    readonly property var mpris: QsMedia.Players
    readonly property var notifs: QsNotifications.Notifs
    readonly property var screenshot: QsScreenshot.Screenshot
    readonly property var idleInhibitor: QsPower.IdleInhibitor

    // Process launchers for header buttons
    Process {
        id: powerProcess
        command: ["wlogout"]
        onStarted: root.shouldShow = false
    }

    Process {
        id: screenshotsProcess
        command: ["wezterm", "start", "--", "yazi", root.screenshot.screenshotsDir]
        onStarted: root.shouldShow = false
    }

    ColumnLayout {
        id: innerCol
        anchors.fill: parent
            spacing: QsTheme.Appearance.spacing.l

            // Header Section
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                spacing: QsTheme.Appearance.spacing.m

                // Time & Date
                ColumnLayout {
                    spacing: QsTheme.Appearance.spacing.xs

                    Text {
                        id: timeText
                        text: Qt.formatTime(new Date(), "hh:mm")
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.headlineLarge.size
                        font.weight: Font.Bold
                        color: QsTheme.Theme.text
                    }

                    Text {
                        text: Qt.formatDate(new Date(), "dddd, MMMM d")
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                        font.weight: Font.Medium
                        color: QsTheme.Theme.textVariant
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Header Actions
                RowLayout {
                    spacing: QsTheme.Appearance.spacing.s

                    HeaderButton {
                        glyph: "󰐥"
                        text: "Power Menu"
                        onClicked: powerProcess.running = true
                    }
                }
            }

            // 上段(トグル〜メディア): 固定・スクロールしない
            ColumnLayout {
                id: upperCol
                Layout.fillWidth: true
                spacing: QsTheme.Appearance.spacing.l

                // Quick Actions
                QsCC.QuickActions {
                    Layout.fillWidth: true
                    onRequestClose: root.shouldShow = false
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: QsTheme.Theme.border
                }

                // Sliders Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: QsTheme.Appearance.spacing.m

                    QsAudioUi.VolumeRow {
                        Layout.fillWidth: true
                        audio: root.audio
                    }

                    // アプリ単位ミキサー（展開トグル）
                    ColumnLayout {
                        id: mixerSection
                        Layout.fillWidth: true
                        Layout.leftMargin: QsTheme.Appearance.spacing.xs
                        Layout.rightMargin: QsTheme.Appearance.spacing.xs
                        spacing: QsTheme.Appearance.spacing.s

                        property bool expanded: false

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 22

                            RowLayout {
                                anchors.fill: parent
                                spacing: QsTheme.Appearance.spacing.s

                                Text {
                                    text: "󰕾"
                                    font.family: QsTheme.Appearance.typography.iconFamily
                                    font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                                    color: QsTheme.Theme.textVariant
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "アプリ音量"
                                    font.family: QsTheme.Appearance.typography.family
                                    font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                                    font.weight: Font.DemiBold
                                    color: QsTheme.Theme.textVariant
                                }

                                Text {
                                    text: mixerSection.expanded ? "󰅀" : "󰅂"
                                    font.family: QsTheme.Appearance.typography.iconFamily
                                    font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                                    color: QsTheme.Theme.textVariant
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mixerSection.expanded = !mixerSection.expanded
                            }
                        }

                        // 展開アニメ: clip した枠の高さを 0↔内容高 で補間
                        Item {
                            Layout.fillWidth: true
                            clip: true
                            implicitHeight: mixerSection.expanded ? mixer.implicitHeight : 0

                            Behavior on implicitHeight {
                                NumberAnimation {
                                    duration: QsTheme.Appearance.anim.durations.medium2
                                    easing.bezierCurve: QsTheme.Appearance.anim.curves.emphasizedDecel
                                }
                            }

                            QsAudioUi.AppVolumeMixer {
                                id: mixer
                                width: parent.width
                                opacity: mixerSection.expanded ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: QsTheme.Appearance.anim.durations.short3
                                        easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                                    }
                                }
                            }
                        }
                    }
                }


                // Media Card
                QsMediaUi.MediaCard {
                    id: mediaCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: mediaCard.hasPlayer ? 100 : 0

                    Behavior on Layout.preferredHeight {
                        NumberAnimation {
                            duration: QsTheme.Appearance.anim.durations.medium2
                            easing.bezierCurve: QsTheme.Appearance.anim.curves.emphasizedDecel
                        }
                    }

                    mpris: root.mpris
                }
            }

            // Notifications: パネル内の余りを埋め、超過分は内部スクロール
            QsNotificationsUi.NotificationList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 160
                notifs: root.notifs
            }
        }

    // CC ヘッダーの丸ボタン。見た目はここで決め、状態と入力は ui/Button に任せる。
    component HeaderButton: Button {
        id: headerBtn

        property string glyph

        implicitWidth: 40
        implicitHeight: 40

        background: Rectangle {
            radius: height / 2
            color: headerBtn.hovered ? QsTheme.Theme.cardHigh : QsTheme.Theme.card
            scale: headerBtn.pressed ? 0.92 : 1.0


            Behavior on scale {
                NumberAnimation {
                    duration: QsTheme.Appearance.anim.durations.short2
                    easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                }
            }
        }

        contentItem: Text {
            text: headerBtn.glyph
            font: QsTheme.Appearance.font.icon
            color: QsTheme.Theme.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        ToolTip {
            visible: headerBtn.hovered && headerBtn.text !== ""
            text: headerBtn.text
            delay: 500

            contentItem: Text {
                text: headerBtn.text
                font: QsTheme.Appearance.font.label
                color: QsTheme.Theme.text
            }

            background: Rectangle {
                radius: QsTheme.Appearance.radius.s
                color: QsTheme.Theme.card
                border.width: 1
                border.color: QsTheme.Theme.border
            }
        }
    }
}
