import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import "../../services" as QsServices
import "../../config" as QsConfig
import "../../components"
import "../../components/effects"
import "components"

PanelWindow {
    id: root
    
    // Services
    readonly property var logger: QsServices.Logger
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
    readonly property color cSurface: QsConfig.Theme.panel
    readonly property color cSurfaceContainer: QsConfig.Theme.card
    readonly property color cSurfaceContainerHigh: QsConfig.Theme.card
    readonly property color cBorder: QsConfig.Theme.border
    readonly property color cPrimary: QsConfig.Theme.accent
    readonly property color cSecondary: QsConfig.Theme.secondary
    readonly property color cOnSurface: QsConfig.Theme.text
    readonly property color cOnSurfaceVariant: QsConfig.Theme.textMuted
    readonly property color cOnSurfaceDim: QsConfig.Theme.textDim
    
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
            NumberAnimation { duration: 260; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.bezierCurve: Material3Anim.standard }
        }

        Behavior on revealOffsetX {
            NumberAnimation { duration: 260; easing.bezierCurve: Material3Anim.emphasizedDecelerate }
        }

        Behavior on revealOffsetY {
            NumberAnimation { duration: 260; easing.bezierCurve: Material3Anim.emphasizedDecelerate }
        }
        
        // Main Panel Background
        AuroraSurface {
            id: panel
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.rightMargin: 12
            width: 420
            height: Math.min(innerCol.implicitHeight + 40, root.screen.height - 56)
            color: root.cSurface
            radius: 24
            strokeColor: root.cBorder
            clip: true
            accentColor: root.cPrimary
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
                anchors.margins: 20
                spacing: 16
                
                // Header Section
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    spacing: 12
                    
                    // Time & Date
                    ColumnLayout {
                        spacing: 2
                        
                        Text {
                            id: timeText
                            text: Qt.formatTime(new Date(), "hh:mm")
                            font.family: "Inter"
                            font.pixelSize: 32
                            font.weight: Font.Bold
                            color: root.cOnSurface
                        }
                        
                        Text {
                            text: Qt.formatDate(new Date(), "dddd, MMMM d")
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: root.cOnSurfaceVariant
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
                        spacing: 6
                        
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
                    spacing: 14

                        // Quick Toggles
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 10
                            rowSpacing: 10
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰖩"
                                label: "Wi-Fi"
                                subLabel: root.network.connected ? root.network.ssid : "Disconnected"
                                active: root.network.wifiEnabled
                                activeColor: root.cPrimary
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: root.network.toggleWifi()
                            }
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰂯"
                                label: "Bluetooth"
                                subLabel: root.bluetooth.powered ? "On" : "Off"
                                active: root.bluetooth.powered
                                activeColor: root.cPrimary
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: root.bluetooth.togglePower()
                            }
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                icon: "󰔎"
                                label: "Do Not Disturb"
                                subLabel: root.notifs.dnd ? "On" : "Off"
                                active: root.notifs.dnd
                                activeColor: QsConfig.Theme.accent
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: root.notifs.toggleDnd()
                            }
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                icon: root.idleInhibitor.inhibited ? "󰈈" : "󰈉"
                                label: "Caffeine"
                                subLabel: root.idleInhibitor.inhibited ? "Active" : "Off"
                                active: root.idleInhibitor.inhibited
                                activeColor: QsConfig.Theme.info
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: root.idleInhibitor.inhibited = !root.idleInhibitor.inhibited
                            }
                            
                            QuickToggle {
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
                                icon: "󰹑"
                                label: "Screenshot"
                                subLabel: "Capture Screen"
                                active: false
                                activeColor: root.cSecondary
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: root.screenshot.takeScreenshot("screen")
                            }

                            QuickToggle {
                                Layout.fillWidth: true
                                enabled: root.screenshot.recorderAvailable
                                opacity: enabled ? 1.0 : 0.5
                                icon: root.screenshot.isRecording ? "󰛿" : "󰻃"
                                label: root.screenshot.isRecording ? "Stop Recording" : "Record Screen"
                                subLabel: !root.screenshot.recorderAvailable
                                    ? "Install wf-recorder"
                                    : (root.screenshot.isRecording ? "Recording in progress" : "Start wf-recorder")
                                active: root.screenshot.isRecording
                                activeColor: QsConfig.Theme.error
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
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
                                activeColor: root.cSecondary
                                surfaceColor: root.cSurfaceContainerHigh
                                textColor: root.cOnSurface
                                onClicked: screenshotsProcess.running = true
                            }
                        }
                        
                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: root.cBorder
                        }
                        
                        // Sliders Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            
                            VolumeSlider {
                                Layout.fillWidth: true
                                audio: root.audio
                            }

                            // アプリ単位ミキサー（展開トグル）
                            ColumnLayout {
                                id: mixerSection
                                Layout.fillWidth: true
                                Layout.leftMargin: 4
                                Layout.rightMargin: 4
                                spacing: 8

                                property bool expanded: false

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 22

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 6

                                        Text {
                                            text: "󰕾"
                                            font.family: "Material Design Icons"
                                            font.pixelSize: 14
                                            color: root.cOnSurfaceVariant
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "アプリ音量"
                                            font.family: "Inter"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            color: root.cOnSurfaceVariant
                                        }

                                        Text {
                                            text: mixerSection.expanded ? "󰅀" : "󰅂"
                                            font.family: "Material Design Icons"
                                            font.pixelSize: 16
                                            color: root.cOnSurfaceVariant
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
                            color: root.cBorder
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
        radius: 20
        color: headerBtnMouse.containsMouse 
            ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.1) 
            : root.cSurfaceContainer
        
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
            font.family: "Material Design Icons"
            font.pixelSize: 18
            color: root.cOnSurface
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
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.cOnSurface
            }

            background: Rectangle {
                radius: 8
                color: root.cSurfaceContainerHigh
                border.width: 1
                border.color: root.cBorder
            }
        }
    }
}
