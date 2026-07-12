import QtQuick 6.10
import "../services" as QsServices
import "../config" as QsConfig

Item {
    id: root

    property color color: QsConfig.Theme.panel
    property color strokeColor: QsConfig.Theme.border
    property color accentColor: QsConfig.Theme.accent
    property color shadowColor: QsConfig.Theme.shadow
    property real radius: 20
    property real borderWidth: 1
    property int elevation: 2
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
        ? QsConfig.Theme.cardHigh
        : root.hovered
            ? QsConfig.Theme.card
            : root.color
    readonly property color resolvedBorderColor: root.highlighted
        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.28)
        : root.hovered
            ? QsConfig.Theme.withAlpha(QsConfig.Theme.outline, 0.7)
            : root.strokeColor
    readonly property real stateLayerOpacity: root.highlighted
        ? root.accentOpacity
        : root.hovered
            ? root.highlightOpacity
            : 0

    Elevation {
        level: root.highlighted ? root.elevation + 2 : root.hovered ? root.elevation + 1 : root.elevation
        target: surface
        radius: surface.radius
        shadowColor: Qt.rgba(root.shadowColor.r, root.shadowColor.g, root.shadowColor.b, root.highlighted ? 0.24 : 0.18)
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: root.radius
        color: root.resolvedSurfaceColor
        border.width: root.borderWidth
        border.color: root.resolvedBorderColor
        clip: root.clipContent

        Behavior on color {
            ColorAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 180
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
                    duration: 180
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