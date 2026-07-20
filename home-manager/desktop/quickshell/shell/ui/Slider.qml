import QtQuick 6.10
import QtQuick.Templates 6.10 as T
import "../theme" as QsTheme

// 値の調整。Track（背景）/ Indicator（進捗）/ Thumb（つまみ）の 3 層。
// ドラッグの座標計算は Templates が持つ。
T.Slider {
    id: root

    // sm | default
    property string size: "default"

    readonly property var metrics: QsTheme.Appearance.size.slider[root.size === "sm" ? "sm" : "normal"]

    implicitWidth: 200
    implicitHeight: root.metrics.thumb
    opacity: root.enabled ? 1 : 0.5

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        width: root.availableWidth
        height: root.metrics.track
        radius: height / 2
        color: QsTheme.Theme.cardHigh

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: QsTheme.Theme.primary
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2
        implicitWidth: root.metrics.thumb
        implicitHeight: root.metrics.thumb
        radius: height / 2
        color: QsTheme.Theme.primary
        border.width: 2
        border.color: QsTheme.Theme.panel
    }

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
