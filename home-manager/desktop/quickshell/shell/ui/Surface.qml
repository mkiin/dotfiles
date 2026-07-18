import QtQuick 6.10
import QtQuick.Effects
import "../theme" as QsTheme

// 角丸・枠線・影を持つ面。中身は default property で受ける。
Item {
    id: root

    property color color: QsTheme.Theme.panel
    property color strokeColor: QsTheme.Theme.border
    property color shadowColor: QsTheme.Theme.shadow
    property real radius: QsTheme.Appearance.radius.l
    property real borderWidth: 1
    property real shadowOpacity: 0.18
    property bool clipContent: true

    default property alias content: contentItem.data

    implicitWidth: contentItem.implicitWidth
    implicitHeight: contentItem.implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.width: root.borderWidth
        border.color: root.strokeColor
        clip: root.clipContent

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowOpacity: root.shadowOpacity
            shadowBlur: 0.4
            shadowVerticalOffset: 4
        }

        Behavior on color {
            ColorAnimation {
                duration: QsTheme.Appearance.anim.durations.normal
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: contentItem
            anchors.fill: parent
        }
    }
}
