import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme" as QsTheme
import "../../services" as QsServices
import "../../utils" as QsUtils
import "../../config" as QsConfig

// ═══════════════════════════════════════════════════════════════════════════
// Material 3 Expressive Notification Popups — Revamped
// ═══════════════════════════════════════════════════════════════════════════
PanelWindow {
    id: root

    readonly property var notifs: QsServices.Notifs
    readonly property var logger: QsUtils.Logger
    readonly property var config: QsConfig.Config

    // ── Color Tokens (semantic, from Theme) ──
    readonly property color m3Surface: QsTheme.Theme.card
    readonly property color m3SurfaceContainer: QsTheme.Theme.panel
    readonly property color m3SurfaceContainerHigh: QsTheme.Theme.cardHigh
    readonly property color m3Primary: QsTheme.Theme.accent
    readonly property color m3OnSurface: QsTheme.Theme.text
    readonly property color m3OnSurfaceVariant: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.55)
    readonly property color m3Error: QsTheme.Theme.error
    readonly property color m3Warning: QsTheme.Theme.warning
    readonly property color m3Success: QsTheme.Theme.success
    readonly property color m3Border: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.06)

    // Swipe dismiss threshold (fraction of popup width)
    readonly property real swipeThreshold: 0.30

    readonly property int hairline: 1
    readonly property int pulseDuration: 1000

    function _urgencyColor(u) {
        if (u === NotificationUrgency.Critical) return m3Error
        if (u === NotificationUrgency.Low) return m3OnSurfaceVariant
        return m3Primary
    }

    // Active popups — newest first, capped to maxVisible
    readonly property var activePopups: (notifs.notifications || [])
        .filter(n => !!n && !n.closed)
        .slice(0, config.notifications.maxVisible)

    // スタック表示: 新着(index 0)を最前面、古いカードは背後に stackPeek ずつのぞかせる。
    readonly property int stackDepth: 2
    readonly property real stackPeek: 12
    property real frontHeight: 0

    // ── Window Setup ──
    screen: [...Quickshell.screens].find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { top: config.notifications.margin; right: config.notifications.margin }
    visible: activePopups.length > 0
    color: "transparent"
    implicitWidth: config.notifications.popupWidth
    implicitHeight: notifStack.height

    Behavior on implicitHeight {
        NumberAnimation { duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.OutCubic }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // NOTIFICATION STACK
    // ═══════════════════════════════════════════════════════════════════════
    Item {
        id: notifStack
        width: parent.width
        height: root.frontHeight
            + Math.min(Math.max(root.activePopups.length - 1, 0), root.stackDepth) * root.stackPeek

        Repeater {
            model: root.activePopups

            // ───────────────────────────────────────────────────────────────
            // NOTIFICATION CARD
            // ───────────────────────────────────────────────────────────────
            Item {
                id: notifCard

                required property var modelData
                required property int index

                // appIcon が空でも image にアイコン URL (image://icon/...) が入る通知があるため流用する。
                readonly property string headerIcon: {
                    const ic = modelData.appIcon
                    if (ic && ic.length > 0)
                        return (ic.startsWith("/") || ic.startsWith("file://") || ic.startsWith("image://"))
                            ? ic : "image://icon/" + ic
                    const im = modelData.image
                    return (im && im.startsWith("image://icon/")) ? im : ""
                }
                property bool headerIconFailed: false

                width: config.notifications.popupWidth
                height: cardWrapper.height
                clip: true

                y: notifCard.dismissing ? notifCard.frozenY : Math.min(notifCard.index, root.stackDepth) * root.stackPeek
                z: notifCard.dismissing ? 9999 : root.activePopups.length - notifCard.index
                visible: notifCard.index <= root.stackDepth

                Behavior on y {
                    NumberAnimation { duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.OutCubic }
                }

                Binding {
                    target: root
                    property: "frontHeight"
                    value: cardWrapper.height
                    when: notifCard.index === 0
                }

                // ── State ──
                property bool isVisible: true
                property bool isHovered: false
                property bool isDragging: false
                property bool isExpanded: false
                property real dragX: 0
                property real timeoutProgress: 1.0
                property bool dismissing: false
                property real frozenY: 0

                // ── Entrance animation properties ──
                property real entryScale: 0.92
                property real entryY: -16
                property real entryOpacity: 0
                property real entryRotation: 0

                Component.onCompleted: {
                    if (!modelData.hasAnimated) {
                        modelData.hasAnimated = true
                        entranceAnim.start()
                    } else {
                        entryScale = 1.0
                        entryY = 0
                        entryOpacity = 1.0
                    }
                }

                // ── Entrance: spring drop-in from above ──
                SequentialAnimation {
                    id: entranceAnim

                    PauseAnimation { duration: notifCard.index * 20 }

                    ParallelAnimation {
                        NumberAnimation {
                            target: notifCard; property: "entryOpacity"
                            from: 0; to: 1.0
                            duration: QsTheme.Appearance.anim.durations.fast; easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryScale"
                            from: 0.92; to: 1.0
                            duration: QsTheme.Appearance.anim.durations.normal
                            easing.type: Easing.OutBack; easing.overshoot: 1.05
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryY"
                            from: -16; to: 0
                            duration: QsTheme.Appearance.anim.durations.normal
                            easing.type: Easing.OutBack; easing.overshoot: 1.05
                        }
                    }
                }

                // ── Exit: swipe right ──
                SequentialAnimation {
                    id: exitRight

                    ParallelAnimation {
                        NumberAnimation {
                            target: notifCard; property: "dragX"
                            to: config.notifications.popupWidth + 60
                            duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryRotation"
                            to: 4; duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryOpacity"
                            to: 0.3; duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.InQuad
                        }
                    }
                    NumberAnimation {
                        target: notifCard; property: "height"
                        to: 0; duration: QsTheme.Appearance.anim.durations.fast; easing.type: Easing.InCubic
                    }
                    ScriptAction { script: modelData.close() }
                }

                // ── Exit: swipe left ──
                SequentialAnimation {
                    id: exitLeft

                    ParallelAnimation {
                        NumberAnimation {
                            target: notifCard; property: "dragX"
                            to: -(config.notifications.popupWidth + 60)
                            duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryRotation"
                            to: -4; duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryOpacity"
                            to: 0.3; duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.InQuad
                        }
                    }
                    NumberAnimation {
                        target: notifCard; property: "height"
                        to: 0; duration: QsTheme.Appearance.anim.durations.fast; easing.type: Easing.InCubic
                    }
                    ScriptAction { script: modelData.close() }
                }

                // ── Snap back (spring) ──
                ParallelAnimation {
                    id: snapBack

                    NumberAnimation {
                        target: notifCard; property: "dragX"
                        to: 0; duration: QsTheme.Appearance.anim.durations.medium
                        easing.type: Easing.OutBack; easing.overshoot: 1.3
                    }
                    NumberAnimation {
                        target: notifCard; property: "entryRotation"
                        to: 0; duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.OutCubic
                    }
                }

                // ── Standard dismiss (scale + fade) ──
                SequentialAnimation {
                    id: dismissAnim

                    ParallelAnimation {
                        NumberAnimation {
                            target: notifCard; property: "entryScale"
                            to: 0.9; duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryOpacity"
                            to: 0; duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: notifCard; property: "entryY"
                            to: -20; duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.InCubic
                        }
                    }
                    ScriptAction { script: modelData.close() }
                }

                function dismiss() {
                    frozenY = y
                    dismissing = true
                    isVisible = false
                    dismissAnim.start()
                }

                function swipeDismiss(direction) {
                    frozenY = y
                    dismissing = true
                    isVisible = false
                    if (direction > 0) exitRight.start()
                    else exitLeft.start()
                }

                // ───────────────────────────────────────────────────────────
                // CARD WRAPPER (holds swipe transforms)
                // ───────────────────────────────────────────────────────────
                Item {
                    id: cardWrapper
                    width: parent.width
                    height: cardBg.height
                    x: notifCard.dragX
                    scale: notifCard.entryScale
                    opacity: notifCard.entryOpacity
                    transformOrigin: Item.Top

                    // Physics-feel rotation during drag
                    rotation: notifCard.entryRotation +
                              (notifCard.isDragging ? notifCard.dragX * 0.015 : 0)

                    transform: Translate { y: notifCard.entryY }

                    // ── Swipe indicator (behind card) ──
                    Rectangle {
                        anchors.fill: cardBg
                        radius: cardBg.radius
                        visible: Math.abs(notifCard.dragX) > 20
                        opacity: Math.min(0.85,
                            Math.abs(notifCard.dragX) /
                            (config.notifications.popupWidth * root.swipeThreshold * 1.5))

                        color: notifCard.dragX > 0
                            ? Qt.rgba(root.m3Error.r, root.m3Error.g, root.m3Error.b, 0.06)
                            : Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: notifCard.dragX > 0 ? "󰅖" : "󰄬"
                            font.family: QsTheme.Appearance.typography.iconFamily
                            font.pixelSize: QsTheme.Appearance.typography.headlineSmall.size
                            color: notifCard.dragX > 0 ? root.m3Error : root.m3Primary
                            opacity: 0.55
                        }
                    }

                    // ═══════════════════════════════════════════════════════
                    // CARD BACKGROUND
                    // ═══════════════════════════════════════════════════════
                    Rectangle {
                        id: cardBg
                        width: parent.width
                        height: contentCol.implicitHeight + 34
                        radius: QsTheme.Appearance.radius.m
                        color: root.m3Surface

                        // Hover-responsive border
                        border.width: 1
                        border.color: {
                            if (notifCard.isHovered)
                                return Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.2)
                            if (modelData.urgency === NotificationUrgency.Critical)
                                return Qt.rgba(root.m3Error.r, root.m3Error.g, root.m3Error.b, 0.2)
                            return root.m3Border
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: QsTheme.Appearance.anim.durations.medium; easing.type: Easing.OutCubic }
                        }

                        // Elevation shadow — lifts on hover
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0, 0.18)
                            shadowBlur: 0.4
                            shadowVerticalOffset: 4
                        }

                        // ── Top accent stripe (urgency indicator) ──
                        Rectangle {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                topMargin: root.hairline
                                leftMargin: QsTheme.Appearance.margin.l
                                rightMargin: QsTheme.Appearance.margin.l
                            }
                            height: 2.5
                            radius: height / 2
                            color: root._urgencyColor(modelData.urgency)
                            opacity: modelData.urgency === NotificationUrgency.Low ? 0.3 : 0.65

                            // Gentle pulse for critical
                            SequentialAnimation on opacity {
                                running: modelData.urgency === NotificationUrgency.Critical
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 0.3; duration: root.pulseDuration
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 0.9; duration: root.pulseDuration
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }

                        // ── Hover glow overlay ──
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: root.m3OnSurface
                            opacity: notifCard.isHovered && !notifCard.isDragging ? 0.035 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.OutCubic }
                            }
                        }

                        // ── Urgency tint (low / critical only) ──
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            z: -1
                            visible: modelData.urgency !== NotificationUrgency.Normal
                            color: {
                                const c = root._urgencyColor(modelData.urgency)
                                if (modelData.urgency === NotificationUrgency.Critical)
                                    return Qt.rgba(c.r, c.g, c.b, 0.08)
                                return Qt.rgba(c.r, c.g, c.b, 0.04)
                            }
                        }

                        // ── Progress bar (bottom sweep) ──
                        Rectangle {
                            id: progressTrack
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                                bottomMargin: QsTheme.Appearance.margin.xs
                                leftMargin: QsTheme.Appearance.margin.l
                                rightMargin: QsTheme.Appearance.margin.l
                            }
                            height: 2
                            radius: height / 2
                            color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g,
                                           root.m3OnSurface.b, 0.04)
                            visible: notifCard.isVisible && !notifCard.isHovered
                            clip: true

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: progressTrack.width * notifCard.timeoutProgress
                                radius: parent.radius
                                color: {
                                    const c = root._urgencyColor(modelData.urgency)
                                    return Qt.rgba(c.r, c.g, c.b, 0.45)
                                }

                                NumberAnimation {
                                    id: progressAnim
                                    target: notifCard
                                    property: "timeoutProgress"
                                    from: 1.0; to: 0
                                    duration: config.notifications.timeoutMs
                                    running: notifCard.isVisible
                                    onFinished: if (notifCard.isVisible) notifCard.dismiss()
                                }
                            }
                        }

                        // Pause progress on hover / drag
                        Connections {
                            target: notifCard
                            function onIsHoveredChanged() {
                                if (progressAnim.running)
                                    progressAnim.paused = notifCard.isHovered || notifCard.isDragging
                            }
                            function onIsDraggingChanged() {
                                if (progressAnim.running)
                                    progressAnim.paused = notifCard.isHovered || notifCard.isDragging
                            }
                        }

                        // ═══════════════════════════════════════════════════
                        // GESTURE AREA
                        // ═══════════════════════════════════════════════════
                        MouseArea {
                            id: gestureArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                            property real startX: 0
                            property bool gestureStarted: false
                            property real scrollAccum: 0
                            property bool isScrolling: false

                            onEntered: notifCard.isHovered = true
                            onExited: {
                                if (!pressed && !isScrolling)
                                    notifCard.isHovered = false
                            }

                            // ── Two-finger swipe (trackpad) ──
                            onWheel: wheel => {
                                if (Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y)) {
                                    wheel.accepted = true
                                    scrollAccum += wheel.angleDelta.x * 0.5
                                    notifCard.dragX = scrollAccum
                                    isScrolling = true
                                    notifCard.isDragging = true
                                    scrollTimer.restart()

                                    const thresh = config.notifications.popupWidth * root.swipeThreshold
                                    if (Math.abs(scrollAccum) > thresh) {
                                        scrollTimer.stop()
                                        isScrolling = false
                                        notifCard.swipeDismiss(scrollAccum)
                                        scrollAccum = 0
                                    }
                                }
                            }

                            Timer {
                                id: scrollTimer
                                interval: 300
                                onTriggered: {
                                    gestureArea.isScrolling = false
                                    notifCard.isDragging = false
                                    const thresh = config.notifications.popupWidth * root.swipeThreshold
                                    if (Math.abs(gestureArea.scrollAccum) > thresh)
                                        notifCard.swipeDismiss(gestureArea.scrollAccum)
                                    else
                                        snapBack.start()
                                    gestureArea.scrollAccum = 0
                                }
                            }

                            // ── Drag gesture ──
                            onPressed: mouse => {
                                startX = mouse.x
                                gestureStarted = false
                                notifCard.isDragging = false
                                scrollAccum = 0
                            }

                            onPositionChanged: mouse => {
                                if (!pressed) return
                                const dx = mouse.x - startX
                                if (!gestureStarted && Math.abs(dx) > 10) {
                                    gestureStarted = true
                                    notifCard.isDragging = true
                                }
                                if (notifCard.isDragging)
                                    notifCard.dragX = dx * 0.8
                            }

                            onReleased: mouse => {
                                notifCard.isDragging = false
                                if (!containsMouse) notifCard.isHovered = false
                                const thresh = config.notifications.popupWidth * root.swipeThreshold
                                if (Math.abs(notifCard.dragX) > thresh)
                                    notifCard.swipeDismiss(notifCard.dragX)
                                else
                                    snapBack.start()
                            }

                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    notifCard.dismiss()
                                } else if (!gestureStarted) {
                                    // Single action → invoke; else toggle expand
                                    if (modelData.actions && modelData.actions.length === 1) {
                                        modelData.actions[0].invoke()
                                        notifCard.dismiss()
                                    } else {
                                        notifCard.isExpanded = !notifCard.isExpanded
                                    }
                                }
                            }
                        }

                        // ═══════════════════════════════════════════════════
                        // CONTENT LAYOUT
                        // ═══════════════════════════════════════════════════
                        ColumnLayout {
                            id: contentCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: QsTheme.Appearance.margin.m
                                topMargin: QsTheme.Appearance.margin.l
                            }
                            spacing: QsTheme.Appearance.spacing.s

                            // ── Header Row ──
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: QsTheme.Appearance.spacing.m

                                // App icon — rounded square with urgency tint
                                Rectangle {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 34
                                    radius: QsTheme.Appearance.radius.s
                                    color: Qt.rgba(
                                        root._urgencyColor(modelData.urgency).r,
                                        root._urgencyColor(modelData.urgency).g,
                                        root._urgencyColor(modelData.urgency).b, 0.12)

                                    // App icon image
                                    Image {
                                        anchors.centerIn: parent
                                        width: 18; height: 18
                                        visible: notifCard.headerIcon.length > 0 && !notifCard.headerIconFailed
                                        source: notifCard.headerIcon
                                        sourceSize: Qt.size(48, 48)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true; cache: true; asynchronous: true
                                        onStatusChanged: {
                                            if (status === Image.Error)
                                                notifCard.headerIconFailed = true
                                            else if (status === Image.Ready)
                                                notifCard.headerIconFailed = false
                                        }
                                    }

                                    // Fallback icon
                                    Text {
                                        anchors.centerIn: parent
                                        visible: notifCard.headerIcon.length === 0 || notifCard.headerIconFailed
                                        text: "󰂞"
                                        font.family: QsTheme.Appearance.typography.iconFamily
                                        font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                                        color: root._urgencyColor(modelData.urgency)
                                        opacity: 0.8
                                    }
                                }

                                // App name + timestamp
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: root.hairline

                                    Text {
                                        text: modelData.appName || "Notification"
                                        font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                                        font.weight: Font.Medium
                                        font.family: QsTheme.Appearance.typography.family
                                        font.letterSpacing: 0.4
                                        color: root.m3OnSurfaceVariant
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.timeString || "now"
                                        font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                                        font.family: QsTheme.Appearance.typography.family
                                        color: Qt.rgba(root.m3OnSurface.r,
                                                       root.m3OnSurface.g,
                                                       root.m3OnSurface.b, 0.3)
                                    }
                                }

                                // Close button — reveals on hover with spring
                                Rectangle {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    radius: height / 2
                                    opacity: (notifCard.isHovered || closeMA.containsMouse) ? 1 : 0
                                    scale: (notifCard.isHovered || closeMA.containsMouse) ? 1.0 : 0.6
                                    color: closeMA.pressed
                                        ? Qt.rgba(root.m3Error.r, root.m3Error.g,
                                                  root.m3Error.b, 0.18)
                                        : closeMA.containsMouse
                                        ? Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g,
                                                  root.m3OnSurface.b, 0.08)
                                        : "transparent"

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.OutCubic
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: QsTheme.Appearance.anim.durations.medium
                                            easing.type: Easing.OutBack
                                            easing.overshoot: 1.4
                                        }
                                    }
                                    Behavior on color {
                                        ColorAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: QsTheme.Appearance.typography.iconFamily
                                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                                        color: closeMA.containsMouse
                                            ? root.m3Error
                                            : Qt.rgba(root.m3OnSurface.r,
                                                      root.m3OnSurface.g,
                                                      root.m3OnSurface.b, 0.45)

                                        Behavior on color {
                                            ColorAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                                        }
                                    }

                                    MouseArea {
                                        id: closeMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => {
                                            mouse.accepted = true
                                            notifCard.dismiss()
                                        }
                                    }
                                }
                            }

                            // ── Summary (headline) ──
                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: QsTheme.Appearance.spacing.xs
                                text: modelData.summary || ""
                                font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                                font.weight: Font.DemiBold
                                font.family: QsTheme.Appearance.typography.family
                                font.letterSpacing: -0.15
                                color: root.m3OnSurface
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                lineHeight: 1.3
                                visible: text.length > 0
                            }

                            // ── Body (secondary text, expandable) ──
                            Text {
                                Layout.fillWidth: true
                                text: modelData.body || ""
                                font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                                font.family: QsTheme.Appearance.typography.family
                                font.letterSpacing: 0.1
                                color: root.m3OnSurfaceVariant
                                wrapMode: Text.Wrap
                                maximumLineCount: notifCard.isExpanded ? 12 : 3
                                elide: Text.ElideRight
                                lineHeight: 1.4
                                visible: text.length > 0

                                Behavior on maximumLineCount {
                                    NumberAnimation {
                                        duration: QsTheme.Appearance.anim.durations.medium; easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            // ── "Show more" hint ──
                            Text {
                                Layout.fillWidth: true
                                visible: {
                                    const body = modelData.body || ""
                                    return body.length > 80 && !notifCard.isExpanded
                                }
                                text: "tap to expand"
                                font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                                font.family: QsTheme.Appearance.typography.family
                                font.letterSpacing: 0.5
                                color: root.m3OnSurfaceVariant
                                opacity: 0.4
                                horizontalAlignment: Text.AlignLeft
                            }

                            // ── Image preview (実画像のみ。icon は image://icon/ なのでヘッダ側で表示) ──
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                Layout.topMargin: QsTheme.Appearance.spacing.xs
                                visible: modelData.image && modelData.image.length > 0
                                    && !modelData.image.startsWith("image://icon/")

                                Rectangle {
                                    anchors.fill: parent
                                    radius: QsTheme.Appearance.radius.s
                                    clip: true
                                    color: root.m3SurfaceContainer

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: root.hairline
                                        source: {
                                            const im = modelData.image
                                            if (!im || im.startsWith("image://icon/")) return ""
                                            return im.startsWith("/") ? "file://" + im : im
                                        }
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true; cache: true; asynchronous: true
                                    }
                                }
                            }

                            // ── Action buttons (M3 tonal pills) ──
                            Flow {
                                Layout.fillWidth: true
                                Layout.topMargin: QsTheme.Appearance.margin.xs
                                spacing: QsTheme.Appearance.spacing.s
                                visible: modelData.actions && modelData.actions.length > 0

                                Repeater {
                                    model: notifCard.modelData.actions || []

                                    Rectangle {
                                        required property var modelData
                                        required property int index

                                        width: actLabel.width + 22
                                        height: 28
                                        radius: height / 2
                                        color: actMA.pressed
                                            ? Qt.rgba(root.m3Primary.r, root.m3Primary.g,
                                                      root.m3Primary.b, 0.28)
                                            : actMA.containsMouse
                                            ? Qt.rgba(root.m3Primary.r, root.m3Primary.g,
                                                      root.m3Primary.b, 0.18)
                                            : Qt.rgba(root.m3Primary.r, root.m3Primary.g,
                                                      root.m3Primary.b, 0.10)

                                        Behavior on color {
                                            ColorAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                                        }

                                        // Tactile press scale
                                        scale: actMA.pressed ? 0.94 : 1.0
                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: QsTheme.Appearance.anim.durations.fast; easing.type: Easing.OutCubic
                                            }
                                        }

                                        Text {
                                            id: actLabel
                                            anchors.centerIn: parent
                                            text: parent.modelData.text ||
                                                  parent.modelData.identifier
                                            font.pixelSize: QsTheme.Appearance.typography.labelSmall.size
                                            font.weight: Font.Medium
                                            font.family: QsTheme.Appearance.typography.family
                                            font.letterSpacing: 0.3
                                            color: root.m3Primary
                                        }

                                        MouseArea {
                                            id: actMA
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                parent.modelData.invoke()
                                                notifCard.dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
