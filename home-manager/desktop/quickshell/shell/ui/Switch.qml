import QtQuick 6.10
import QtQuick.Templates 6.10 as T
import "../theme" as QsTheme

// ON/OFF のトグル。checked と入力は Templates が持つ。
T.Switch {
    id: root

    // sm | default
    property string size: "default"

    readonly property int trackWidth: root.size === "sm" ? 24 : 32
    readonly property int trackHeight: root.size === "sm" ? 14 : 18
    readonly property int thumbSize: root.trackHeight - 2

    implicitWidth: root.trackWidth
    implicitHeight: root.trackHeight
    padding: 0
    opacity: root.enabled ? 1 : 0.5

    background: Rectangle {
        radius: height / 2
        color: root.checked ? QsTheme.Theme.primary : QsTheme.Theme.cardHigh
    }

    indicator: Rectangle {
        x: root.checked ? root.trackWidth - width - 1 : 1
        y: (root.trackHeight - height) / 2
        width: root.thumbSize
        height: root.thumbSize
        radius: height / 2
        color: root.checked ? QsTheme.Theme.onPrimary : QsTheme.Theme.text
    }

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
