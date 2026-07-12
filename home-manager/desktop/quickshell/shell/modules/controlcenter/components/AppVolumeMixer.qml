import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Services.Pipewire
import "../../../components/effects"
import "../../../services" as QsServices
import "../../../config" as QsConfig

ColumnLayout {
    id: root

    readonly property var streams: QsServices.AudioStreams.streams
    readonly property var groups: QsServices.AudioStreams.groups

    spacing: QsConfig.Appearance.spacing.s

    PwObjectTracker { objects: root.streams }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: QsConfig.Appearance.spacing.xs
        Layout.bottomMargin: QsConfig.Appearance.spacing.xs
        visible: root.groups.length === 0
        text: "再生中のアプリはありません"
        font.family: QsConfig.Appearance.typography.family
        font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
        color: QsConfig.Theme.textMuted
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
            radius: QsConfig.Appearance.radius.m
            color: QsConfig.Theme.cardHigh
            border.width: 1
            border.color: QsConfig.Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: QsConfig.Appearance.margin.m
                anchors.rightMargin: QsConfig.Appearance.margin.m
                anchors.topMargin: QsConfig.Appearance.margin.s
                anchors.bottomMargin: QsConfig.Appearance.margin.s
                spacing: QsConfig.Appearance.spacing.xs

                Text {
                    Layout.fillWidth: true
                    text: row.modelData.name
                    elide: Text.ElideRight
                    font.family: QsConfig.Appearance.typography.family
                    font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                    font.weight: Font.DemiBold
                    color: QsConfig.Theme.text
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: QsConfig.Appearance.spacing.s

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: height / 2
                        color: muteMouse.containsMouse
                            ? QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.1)
                            : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Material3Anim.short3
                                easing.bezierCurve: Material3Anim.standard
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: row.isMuted ? "󰝟" : (row.currentVolume > 66 ? "󰕾" : (row.currentVolume > 33 ? "󰖀" : "󰕿"))
                            font.family: QsConfig.Appearance.typography.iconFamily
                            font.pixelSize: QsConfig.Appearance.typography.bodyLarge.size
                            color: row.isMuted
                                ? QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.5)
                                : QsConfig.Theme.accent
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
                        font.family: QsConfig.Appearance.typography.family
                        font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                        font.weight: Font.DemiBold
                        color: QsConfig.Theme.text
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
