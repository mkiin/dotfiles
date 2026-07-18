import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell.Io
import "../../theme" as QsTheme
import "../../services" as QsServices
import "../../utils" as QsUtils
import "../../config" as QsConfig
import "../../components/containers"
import "components"

// 通知センター — 殻(配置/アニメ/クローズ)は FloatingPanel、ここは中身だけ
FloatingPanel {
    id: root

    panelWidth: 420

    // Services
    readonly property var logger: QsUtils.Logger
    readonly property var config: QsConfig.Config
    readonly property var network: QsServices.Network
    readonly property var bluetooth: QsServices.Bluetooth
    readonly property var audio: QsServices.Audio
    readonly property var mpris: QsServices.Players
    readonly property var notifs: QsServices.Notifs
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property var powerProfiles: QsServices.PowerProfiles
    readonly property var screenshot: QsServices.Screenshot
    readonly property var idleInhibitor: QsServices.IdleInhibitor

    // Process launchers for header buttons
    Process {
        id: settingsProcess
        command: ["nm-connection-editor"]
        onStarted: root.shouldShow = false
    }

    Process {
        id: lockProcess
        command: ["hyprlock"]
        onStarted: root.shouldShow = false
    }

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

    // Main Panel Background
    AuroraSurface {
        id: panel
        anchors.fill: parent
        implicitHeight: Math.min(innerCol.implicitHeight + 40, root.screen.height - 56)
        color: QsTheme.Theme.panel
        radius: QsTheme.Appearance.radius.l
        strokeColor: QsTheme.Theme.border
        clip: true
        accentColor: QsTheme.Theme.accent
        highlighted: false

        Behavior on color {
            ColorAnimation {
                duration: QsTheme.Appearance.anim.durations.medium2
                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
            }
        }

        // Block clicks from passing through
        MouseArea {
            anchors.fill: parent
            onClicked: mouse => {
                mouse.accepted = true;
            }
        }

        // Content Layout
        ColumnLayout {
            id: innerCol
            anchors.fill: parent
            anchors.margins: QsTheme.Appearance.margin.l
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
                        color: QsTheme.Theme.textMuted
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
                        icon: "󰒓"
                        tooltip: "Settings"
                        onClicked: settingsProcess.running = true
                    }
                    HeaderButton {
                        icon: "󰍜"
                        tooltip: "Lock Screen"
                        onClicked: lockProcess.running = true
                    }
                    HeaderButton {
                        icon: "󰐥"
                        tooltip: "Power Menu"
                        onClicked: powerProcess.running = true
                    }
                }
            }

            // 上段(トグル〜メディア): 固定・スクロールしない
            ColumnLayout {
                id: upperCol
                Layout.fillWidth: true
                spacing: QsTheme.Appearance.spacing.l

                // Quick Toggles
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: QsTheme.Appearance.spacing.m
                    rowSpacing: QsTheme.Appearance.spacing.m

                    QuickToggle {
                        Layout.fillWidth: true
                        icon: "󰖩"
                        label: "Wi-Fi"
                        subLabel: root.network.connected ? root.network.ssid : "Disconnected"
                        active: root.network.wifiEnabled
                        activeColor: QsTheme.Theme.accent
                        surfaceColor: QsTheme.Theme.card
                        textColor: QsTheme.Theme.text
                        onClicked: root.network.toggleWifi()
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        icon: "󰂯"
                        label: "Bluetooth"
                        subLabel: root.bluetooth.powered ? "On" : "Off"
                        active: root.bluetooth.powered
                        activeColor: QsTheme.Theme.accent
                        surfaceColor: QsTheme.Theme.card
                        textColor: QsTheme.Theme.text
                        onClicked: root.bluetooth.togglePower()
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        icon: "󰔎"
                        label: "Do Not Disturb"
                        subLabel: root.notifs.dnd ? "On" : "Off"
                        active: root.notifs.dnd
                        activeColor: QsTheme.Theme.accent
                        surfaceColor: QsTheme.Theme.card
                        textColor: QsTheme.Theme.text
                        onClicked: root.notifs.toggleDnd()
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        icon: root.idleInhibitor.inhibited ? "󰈈" : "󰈉"
                        label: "Caffeine"
                        subLabel: root.idleInhibitor.inhibited ? "Active" : "Off"
                        active: root.idleInhibitor.inhibited
                        activeColor: QsTheme.Theme.info
                        surfaceColor: QsTheme.Theme.card
                        textColor: QsTheme.Theme.text
                        onClicked: root.idleInhibitor.inhibited = !root.idleInhibitor.inhibited
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        icon: "󰹑"
                        label: "Screenshot"
                        subLabel: "Region / Window / Output"
                        active: false
                        activeColor: QsTheme.Theme.secondary
                        surfaceColor: QsTheme.Theme.card
                        textColor: QsTheme.Theme.text
                        onClicked: {
                            root.shouldShow = false;
                            root.screenshot.openMenu();
                        }
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        enabled: root.screenshot.recorderAvailable
                        opacity: enabled ? 1.0 : 0.5
                        icon: root.screenshot.isRecording ? "󰛿" : "󰻃"
                        label: root.screenshot.isRecording ? "Stop Recording" : "Record Screen"
                        subLabel: !root.screenshot.recorderAvailable ? "Install gpu-screen-recorder" : (root.screenshot.isRecording ? "Recording in progress" : "Start recording")
                        active: root.screenshot.isRecording
                        activeColor: QsTheme.Theme.error
                        surfaceColor: QsTheme.Theme.card
                        textColor: QsTheme.Theme.text
                        onClicked: {
                            if (root.screenshot.isRecording)
                                root.screenshot.stopRecording();
                            else
                                root.screenshot.startRecording();
                        }
                    }

                    QuickToggle {
                        Layout.fillWidth: true
                        icon: "󰉋"
                        label: "Open Captures"
                        subLabel: "Screenshots & recordings"
                        active: false
                        activeColor: QsTheme.Theme.secondary
                        surfaceColor: QsTheme.Theme.card
                        textColor: QsTheme.Theme.text
                        onClicked: screenshotsProcess.running = true
                    }
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

                    VolumeSlider {
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
                                    color: QsTheme.Theme.textMuted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "アプリ音量"
                                    font.family: QsTheme.Appearance.typography.family
                                    font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                                    font.weight: Font.DemiBold
                                    color: QsTheme.Theme.textMuted
                                }

                                Text {
                                    text: mixerSection.expanded ? "󰅀" : "󰅂"
                                    font.family: QsTheme.Appearance.typography.iconFamily
                                    font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                                    color: QsTheme.Theme.textMuted
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

                            AppVolumeMixer {
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

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: QsTheme.Theme.border
                }

                // System Stats
                SystemStats {
                    Layout.fillWidth: true
                    systemUsage: root.systemUsage
                }

                // Media Card
                MediaCard {
                    Layout.fillWidth: true
                    mpris: root.mpris
                }
            }

            // Notifications: パネル内の余りを埋め、超過分は内部スクロール
            NotificationList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 160
                notifs: root.notifs
            }
        }
    }

    // Header Button Component
    component HeaderButton: Rectangle {
        id: headerBtn
        property string icon
        property string tooltip: ""
        signal clicked

        width: 40
        height: 40
        radius: height / 2
        color: headerBtnMouse.containsMouse ? Qt.rgba(QsTheme.Theme.text.r, QsTheme.Theme.text.g, QsTheme.Theme.text.b, 0.1) : QsTheme.Theme.card

        Behavior on color {
            ColorAnimation {
                duration: QsTheme.Appearance.anim.durations.short3
                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
            }
        }

        scale: headerBtnMouse.pressed ? 0.92 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: QsTheme.Appearance.anim.durations.short2
                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
            }
        }

        Text {
            anchors.centerIn: parent
            text: headerBtn.icon
            font.family: QsTheme.Appearance.typography.iconFamily
            font.pixelSize: QsTheme.Appearance.typography.titleMedium.size
            color: QsTheme.Theme.text
        }

        MouseArea {
            id: headerBtnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: headerBtn.clicked()
        }

        ToolTip {
            id: headerBtnTip
            visible: headerBtnMouse.containsMouse && headerBtn.tooltip !== ""
            text: headerBtn.tooltip
            delay: 500

            contentItem: Text {
                text: headerBtnTip.text
                font.family: QsTheme.Appearance.typography.family
                font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                font.weight: Font.Medium
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
