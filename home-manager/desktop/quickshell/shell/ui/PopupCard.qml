import QtQuick 6.10
import QtQuick.Effects
import "../theme" as QsTheme

// パネル/ポップアウトの土台。角丸・枠線・影を持ち、中身は default property で受ける。
// 色の補間アニメは持たない（中間色を作らない方針）。
Rectangle {
    id: root

    property real shadowOpacity: 0.35
    property real shadowBlur: 1.0
    property real shadowOffsetY: 6

    default property alias content: contentItem.data

    implicitWidth: contentItem.implicitWidth
    implicitHeight: contentItem.implicitHeight

    color: QsTheme.Theme.panel
    radius: QsTheme.Appearance.radius.m
    border.width: 1
    border.color: QsTheme.Theme.border

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: QsTheme.Theme.shadow
        shadowOpacity: root.shadowOpacity
        shadowBlur: root.shadowBlur
        shadowVerticalOffset: root.shadowOffsetY
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
