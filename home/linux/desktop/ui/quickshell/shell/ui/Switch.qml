import QtQuick 6.10
import "../theme" as QsTheme

// ON/OFF のトグル。checked は外から与えられた値を描くだけで、内部では持たない。
// 切り替えは clicked を受けた側が行う。
Rectangle {
    id: root

    // sm | default
    property string size: "default"

    property bool checked: false

    signal clicked

    readonly property var track: QsTheme.Appearance.size.switchTrack[root.size === "sm" ? "sm" : "normal"]

    readonly property int trackWidth: root.track.width
    readonly property int trackHeight: root.track.height
    readonly property int thumbSize: root.trackHeight - 2

    // 面と、その上に乗る on-color の組。
    readonly property color surfaceColor: root.checked ? QsTheme.Theme.primary : QsTheme.Theme.cardHigh
    readonly property color onSurfaceColor: root.checked ? QsTheme.Theme._onPrimary : QsTheme.Theme.text

    implicitWidth: root.trackWidth
    implicitHeight: root.trackHeight

    color: root.surfaceColor
    radius: height / 2
    opacity: root.enabled ? 1 : 0.5

    Rectangle {
        x: root.checked ? root.trackWidth - width - 1 : 1
        y: (root.trackHeight - height) / 2
        width: root.thumbSize
        height: root.thumbSize
        radius: height / 2
        color: root.onSurfaceColor
    }

    StateLayer {
        color: root.onSurfaceColor
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
