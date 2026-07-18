import QtQuick 6.10
import QtQuick.Effects
import "../theme" as QsTheme

Item {
    id: root

    property color color: QsTheme.Theme.panel
    property color strokeColor: QsTheme.Theme.border
    property color accentColor: QsTheme.Theme.accent
    property color shadowColor: QsTheme.Theme.shadow
    property real radius: QsTheme.Appearance.radius.l
    property real borderWidth: 1
    property real accentOpacity: 0.10
    property real highlightOpacity: 0.08
    property bool hovered: false
    property bool highlighted: false
    property bool clipContent: true

    default property alias content: contentItem.data
    readonly property alias backgroundItem: surface

    implicitWidth: contentItem.implicitWidth
    implicitHeight: contentItem.implicitHeight

    readonly property color resolvedSurfaceColor: root.highlighted
        ? QsTheme.Theme.cardHigh
        : root.hovered
            ? QsTheme.Theme.card
            : root.color
    readonly property color resolvedBorderColor: root.highlighted
        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.28)
        : root.hovered
            ? QsTheme.Theme.withAlpha(QsTheme.Theme.outline, 0.7)
            : root.strokeColor
    readonly property real stateLayerOpacity: root.highlighted
        ? root.accentOpacity
        : root.hovered
            ? root.highlightOpacity
            : 0

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: root.radius
        color: root.resolvedSurfaceColor
        border.width: root.borderWidth
        border.color: root.resolvedBorderColor
        clip: root.clipContent

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowOpacity: root.highlighted ? 0.24 : 0.18
            shadowBlur: 0.4
            shadowVerticalOffset: 4
        }

        Behavior on color {
            ColorAnimation {
                duration: QsTheme.Appearance.anim.durations.normal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: QsTheme.Appearance.anim.durations.normal
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.borderWidth
            radius: Math.max(0, parent.radius - root.borderWidth)
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, root.stateLayerOpacity)
            opacity: root.stateLayerOpacity > 0 ? 1 : 0

            Behavior on color {
                ColorAnimation {
                    duration: QsTheme.Appearance.anim.durations.normal
                    easing.type: Easing.OutCubic
                }
            }
        }

        Item {
            id: contentItem
            anchors.fill: parent
        }
    }
}