import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Services.Pipewire
import "../../../theme" as QsTheme
import "../../../services" as QsServices

ColumnLayout {
    id: root

    readonly property var streams: QsServices.AudioStreams.streams
    readonly property var groups: QsServices.AudioStreams.groups

    spacing: QsTheme.Appearance.spacing.s

    PwObjectTracker { objects: root.streams }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: QsTheme.Appearance.spacing.xs
        Layout.bottomMargin: QsTheme.Appearance.spacing.xs
        visible: root.groups.length === 0
        text: "再生中のアプリはありません"
        font.family: QsTheme.Appearance.typography.family
        font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
        color: QsTheme.Theme.textMuted
        horizontalAlignment: Text.AlignHCenter
    }

    Repeater {
        model: root.groups

        delegate: Rectangle {
            id: row

            required property var modelData
            readonly property var nodes: modelData.nodes
            readonly property var node: nodes[0]
            readonly property bool isMuted: node.audio ? node.audio.muted : false
            readonly property int currentVolume: node.audio ? Math.round(node.audio.volume * 100) : 0

            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: QsTheme.Appearance.radius.m
            color: QsTheme.Theme.cardHigh
            border.width: 1
            border.color: QsTheme.Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: QsTheme.Appearance.margin.m
                anchors.rightMargin: QsTheme.Appearance.margin.m
                anchors.topMargin: QsTheme.Appearance.margin.s
                anchors.bottomMargin: QsTheme.Appearance.margin.s
                spacing: QsTheme.Appearance.spacing.xs

                Text {
                    Layout.fillWidth: true
                    text: row.modelData.name
                    elide: Text.ElideRight
                    font.family: QsTheme.Appearance.typography.family
                    font.pixelSize: QsTheme.Appearance.typography.labelMedium.size
                    font.weight: Font.DemiBold
                    color: QsTheme.Theme.text
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: QsTheme.Appearance.spacing.s

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: height / 2
                        color: muteMouse.containsMouse
                            ? QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.1)
                            : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: QsTheme.Appearance.anim.durations.short3
                                easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: row.isMuted ? "󰝟" : (row.currentVolume > 66 ? "󰕾" : (row.currentVolume > 33 ? "󰖀" : "󰕿"))
                            font.family: QsTheme.Appearance.typography.iconFamily
                            font.pixelSize: QsTheme.Appearance.typography.bodyLarge.size
                            color: row.isMuted
                                ? QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.5)
                                : QsTheme.Theme.accent
                        }

                        MouseArea {
                            id: muteMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: QsServices.AudioStreams.setGroupMuted(row.nodes, !row.isMuted)
                        }
                    }

                    VolumeTrack {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        value: row.currentVolume
                        surfaceColor: row.color
                        onMoved: QsServices.AudioStreams.setGroupVolume(row.nodes, value / 100)
                        onVolumeStepped: newValue => QsServices.AudioStreams.setGroupVolume(row.nodes, newValue / 100)
                    }

                    Text {
                        Layout.preferredWidth: 44
                        text: row.currentVolume + "%"
                        font.family: QsTheme.Appearance.typography.family
                        font.pixelSize: QsTheme.Appearance.typography.bodyMedium.size
                        font.weight: Font.DemiBold
                        color: QsTheme.Theme.text
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
