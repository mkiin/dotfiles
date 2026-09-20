import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../ui" as QsUi
import "../../theme" as QsTheme
import "../../features/media" as QsMedia

// 再生中メディア。アート / タイトル / 再生コントロールの横並び。
// 表示するかどうか（プレイヤー無しのとき）は置く側が決める。
Rectangle {
    id: root

    readonly property var players: QsMedia.Players

    implicitHeight: row.implicitHeight + QsTheme.Appearance.padding.m * 2

    color: QsTheme.Theme.card
    radius: QsTheme.Appearance.radius.m
    border.width: 1
    border.color: QsTheme.Theme.border

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: QsTheme.Appearance.padding.m
        spacing: QsTheme.Appearance.spacing.m

        Rectangle {
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56
            radius: QsTheme.Appearance.radius.s
            color: QsTheme.Theme.cardHigh
            clip: true

            Image {
                id: albumArt

                anchors.fill: parent
                source: root.players.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: QsTheme.Appearance.iconFamily
                font.pixelSize: QsTheme.Appearance.fontSize.l
                color: QsTheme.Theme.textVariant
                visible: albumArt.status !== Image.Ready
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.players.title || "No Media"
                font.family: QsTheme.Appearance.fontFamily
                font.pixelSize: QsTheme.Appearance.fontSize.m
                font.weight: Font.DemiBold
                color: QsTheme.Theme.text
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.players.artist
                font.family: QsTheme.Appearance.fontFamily
                font.pixelSize: QsTheme.Appearance.fontSize.s
                color: QsTheme.Theme.textVariant
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        RowLayout {
            spacing: QsTheme.Appearance.spacing.xs

            QsUi.Button {
                variant: "ghost"
                iconOnly: true
                text: "󰒮"
                onClicked: root.players.previous()
            }

            QsUi.Button {
                iconOnly: true
                size: "lg"
                text: root.players.playing ? "󰏤" : "󰐊"
                onClicked: root.players.playPause()
            }

            QsUi.Button {
                variant: "ghost"
                iconOnly: true
                text: "󰒭"
                onClicked: root.players.next()
            }
        }
    }
}
