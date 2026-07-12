import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import "../../services" as QsServices
import "../../utils" as QsUtils
import "../../config" as QsConfig
import "../../components/containers"
import "../../components/effects"
import "components"

PanelWindow {
    id: root
    
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
    
    // Solid UI Color Tokens - Professional dark theme
    
    property real barBottom: 40

    // クリックしたモニター（フォーカス中の出力）に追従
    screen: [...Quickshell.screens].find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    // バー下端より下を覆う透明オーバーレイ（枠外クリックで閉じる・バーに被らない）
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
    visible: shouldShow || panelContent.opacity > 0

    property bool shouldShow: false
    
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    // Main Panel Container
    FocusScope {
        id: panelContent
        anchors.fill: parent
        
        transformOrigin: Item.TopRight
        property real revealOffsetX: root.shouldShow ? 0 : 20
        property real revealOffsetY: root.shouldShow ? 0 : -10
        scale: root.shouldShow ? 1.0 : 0.965
        opacity: root.shouldShow ? 1.0 : 0.0
        transform: Translate { x: panelContent.revealOffsetX; y: panelContent.revealOffsetY }
        
        focus: true
        
        Keys.onEscapePressed: root.shouldShow = false
        
        // マウスアウト自動クローズは撤去（Esc ＋ 枠外クリック ＋ ベル再クリックで閉じる）

        onVisibleChanged: {
            if (visible) forceActiveFocus()
        }
        
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.shouldShow = false
        }
        
        Behavior on scale {
            NumberAnimation { duration: QsConfig.Appearance.anim.durations.medium; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
        }

        Behavior on opacity {
            NumberAnimation { duration: QsConfig.Appearance.anim.durations.normal; easing.bezierCurve: Material3Anim.standard }
        }

        Behavior on revealOffsetX {
            NumberAnimation { duration: QsConfig.Appearance.anim.durations.medium; easing.bezierCurve: Material3Anim.emphasizedDecelerate }
        }

        Behavior on revealOffsetY {
            NumberAnimation { duration: QsConfig.Appearance.anim.durations.medium; easing.bezierCurve: Material3Anim.emphasizedDecelerate }
        }
        
        // Main Panel Background
        AuroraSurface {
            id: panel
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: QsConfig.Appearance.margin.s
            anchors.rightMargin: QsConfig.Appearance.margin.m
            width: 420
            height: Math.min(innerCol.implicitHeight + 40, root.screen.height - 56)
            color: QsConfig.Theme.panel
            radius: QsConfig.Appearance.radius.l
            strokeColor: QsConfig.Theme.border
            clip: true
            accentColor: QsConfig.Theme.accent
            elevation: 4
            highlighted: false
            
            Behavior on color {
                ColorAnimation {
                    duration: Material3Anim.medium2
                    easing.bezierCurve: Material3Anim.standard
                }
            }

            // Block clicks from passing through
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => { mouse.accepted = true }
            }
            
            // Content Layout
            ColumnLayout {
                id: innerCol
                anchors.fill: parent
                anchors.margins: QsConfig.Appearance.margin.l
                spacing: QsConfig.Appearance.spacing.l
                
                // Header Section
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    spacing: QsConfig.Appearance.spacing.m
                    
                    // Time & Date
                    ColumnLayout {
                        spacing: QsConfig.Appearance.spacing.xs
                        
                        Text {
                            id: timeText
                            text: Qt.formatTime(new Date(), "hh:mm")
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.headlineLarge.size
                            font.weight: Font.Bold
                            color: QsConfig.Theme.text
                        }
                        
                        Text {
                            text: Qt.formatDate(new Date(), "dddd, MMMM d")
                            font.family: QsConfig.Appearance.typography.family
                            font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                            font.weight: Font.Medium
                            color: QsConfig.Theme.textMuted
                        }
                        
                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Header Actions
                    RowLayout {
                        spacing: QsConfig.Appearance.spacing.s

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
                    spacing: QsConfig.Appearance.spacing.l

                        // Quick Toggles
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: QsConfig.Appearance.spacing.m
                            rowSpacing: QsConfig.Appearance.spacing.m
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰖩"
                                label: "Wi-Fi"
                                subLabel: root.network.connected ? root.network.ssid : "Disconnected"
                                active: root.network.wifiEnabled
                                activeColor: QsConfig.Theme.accent
                                surfaceColor: QsConfig.Theme.card
                                textColor: QsConfig.Theme.text
                                onClicked: root.network.toggleWifi()
                            }
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰂯"
                                label: "Bluetooth"
                                subLabel: root.bluetooth.powered ? "On" : "Off"
                                active: root.bluetooth.powered
                                activeColor: QsConfig.Theme.accent
                                surfaceColor: QsConfig.Theme.card
                                textColor: QsConfig.Theme.text
                                onClicked: root.bluetooth.togglePower()
                            }
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰔎"
                                label: "Do Not Disturb"
                                subLabel: root.notifs.dnd ? "On" : "Off"
                                active: root.notifs.dnd
                                activeColor: QsConfig.Theme.accent
                                surfaceColor: QsConfig.Theme.card
                                textColor: QsConfig.Theme.text
                                onClicked: root.notifs.toggleDnd()
                            }
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                icon: root.idleInhibitor.inhibited ? "󰈈" : "󰈉"
                                label: "Caffeine"
                                subLabel: root.idleInhibitor.inhibited ? "Active" : "Off"
                                active: root.idleInhibitor.inhibited
                                activeColor: QsConfig.Theme.info
                                surfaceColor: QsConfig.Theme.card
                                textColor: QsConfig.Theme.text
                                onClicked: root.idleInhibitor.inhibited = !root.idleInhibitor.inhibited
                            }
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
                                icon: "󰹑"
                                label: "Screenshot"
                                subLabel: "Region / Window / Output"
                                active: false
                                activeColor: QsConfig.Theme.secondary
                                surfaceColor: QsConfig.Theme.card
                                textColor: QsConfig.Theme.text
                                onClicked: {
                                    root.shouldShow = false
                                    root.screenshot.openMenu()
                                }
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                enabled: root.screenshot.recorderAvailable
                                opacity: enabled ? 1.0 : 0.5
                                icon: root.screenshot.isRecording ? "󰛿" : "󰻃"
                                label: root.screenshot.isRecording ? "Stop Recording" : "Record Screen"
                                subLabel: !root.screenshot.recorderAvailable
                                    ? "Install gpu-screen-recorder"
                                    : (root.screenshot.isRecording ? "Recording in progress" : "Start recording")
                                active: root.screenshot.isRecording
                                activeColor: QsConfig.Theme.error
                                surfaceColor: QsConfig.Theme.card
                                textColor: QsConfig.Theme.text
                                onClicked: {
                                    if (root.screenshot.isRecording)
                                        root.screenshot.stopRecording()
                                    else
                                        root.screenshot.startRecording()
                                }
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰉋"
                                label: "Open Captures"
                                subLabel: "Screenshots & recordings"
                                active: false
                                activeColor: QsConfig.Theme.secondary
                                surfaceColor: QsConfig.Theme.card
                                textColor: QsConfig.Theme.text
                                onClicked: screenshotsProcess.running = true
                            }
                        }
                        
                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: QsConfig.Theme.border
                        }
                        
                        // Sliders Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: QsConfig.Appearance.spacing.m
                            
                            VolumeSlider {
                                Layout.fillWidth: true
                                audio: root.audio
                            }

                            // アプリ単位ミキサー（展開トグル）
                            ColumnLayout {
                                id: mixerSection
                                Layout.fillWidth: true
                                Layout.leftMargin: QsConfig.Appearance.spacing.xs
                                Layout.rightMargin: QsConfig.Appearance.spacing.xs
                                spacing: QsConfig.Appearance.spacing.s

                                property bool expanded: false

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 22

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: QsConfig.Appearance.spacing.s

                                        Text {
                                            text: "󰕾"
                                            font.family: QsConfig.Appearance.typography.iconFamily
                                            font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                                            color: QsConfig.Theme.textMuted
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "アプリ音量"
                                            font.family: QsConfig.Appearance.typography.family
                                            font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                                            font.weight: Font.DemiBold
                                            color: QsConfig.Theme.textMuted
                                        }

                                        Text {
                                            text: mixerSection.expanded ? "󰅀" : "󰅂"
                                            font.family: QsConfig.Appearance.typography.iconFamily
                                            font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                                            color: QsConfig.Theme.textMuted
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
                                            duration: Material3Anim.medium2
                                            easing.bezierCurve: Material3Anim.emphasizedDecelerate
                                        }
                                    }

                                    AppVolumeMixer {
                                        id: mixer
                                        width: parent.width
                                        opacity: mixerSection.expanded ? 1 : 0

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Material3Anim.short3
                                                easing.bezierCurve: Material3Anim.standard
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
                            color: QsConfig.Theme.border
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
    }
    
    // Header Button Component
    component HeaderButton: Rectangle {
        id: headerBtn
        property string icon
        property string tooltip: ""
        signal clicked()
        
        width: 40
        height: 40
        radius: height / 2
        color: headerBtnMouse.containsMouse 
            ? Qt.rgba(QsConfig.Theme.text.r, QsConfig.Theme.text.g, QsConfig.Theme.text.b, 0.1) 
            : QsConfig.Theme.card
        
        Behavior on color {
            ColorAnimation {
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }
        
        scale: headerBtnMouse.pressed ? 0.92 : 1.0
        
        Behavior on scale {
            NumberAnimation {
                duration: Material3Anim.short2
                easing.bezierCurve: Material3Anim.standard
            }
        }
        
        Text {
            anchors.centerIn: parent
            text: headerBtn.icon
            font.family: QsConfig.Appearance.typography.iconFamily
            font.pixelSize: QsConfig.Appearance.typography.titleMedium.size
            color: QsConfig.Theme.text
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
                font.family: QsConfig.Appearance.typography.family
                font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                font.weight: Font.Medium
                color: QsConfig.Theme.text
            }

            background: Rectangle {
                radius: QsConfig.Appearance.radius.s
                color: QsConfig.Theme.card
                border.width: 1
                border.color: QsConfig.Theme.border
            }
        }
    }
}
