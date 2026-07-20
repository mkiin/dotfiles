import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../theme" as QsTheme

// 一覧の 1 行。左(media) / 中央(title + description) / 右(actions) の 3 スロット。
// hover / pressed の表現と行のクリックは StateLayer が担う。
Rectangle {
    id: root

    // default | outline | muted
    property string variant: "default"
    // xs | sm | default
    property string size: "default"

    property string title
    property string description

    // 選択中かどうか。ホバーとは別で、こちらだけが面の色を変える。
    property bool highlighted: false

    // 左右のスロット。Item を渡すと配置される。
    property alias media: mediaSlot.data
    property alias actions: actionsSlot.data

    signal clicked

    readonly property int gap: ({
            xs: QsTheme.Appearance.spacing.xs,
            sm: QsTheme.Appearance.spacing.s,
            default: QsTheme.Appearance.spacing.m
        })[root.size]

    readonly property int padX: ({
            xs: QsTheme.Appearance.padding.s,
            sm: QsTheme.Appearance.padding.m,
            default: QsTheme.Appearance.padding.l
        })[root.size]

    readonly property int padY: ({
            xs: QsTheme.Appearance.padding.xs,
            sm: QsTheme.Appearance.padding.s,
            default: QsTheme.Appearance.padding.m
        })[root.size]

    implicitWidth: layout.implicitWidth + root.padX * 2
    implicitHeight: layout.implicitHeight + root.padY * 2

    color: root.highlighted ? QsTheme.Theme.cardHigh : (root.variant === "muted" ? QsTheme.Theme.card : "transparent")
    radius: QsTheme.Appearance.radius.s
    border.width: root.variant === "outline" ? 1 : 0
    border.color: QsTheme.Theme.border
    opacity: root.enabled ? 1 : 0.5

    // 行のクリックと状態表現。中身より下に敷き、actions のボタンの入力を奪わない。
    StateLayer {
        z: -1
        color: QsTheme.Theme.text
        enabled: root.enabled
        onClicked: root.clicked()
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: root.padX
        anchors.rightMargin: root.padX
        anchors.topMargin: root.padY
        anchors.bottomMargin: root.padY
        spacing: root.gap

        Item {
            id: mediaSlot

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
            visible: children.length > 0
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.size === "xs" ? 0 : QsTheme.Appearance.spacing.xs

            Text {
                Layout.fillWidth: true
                text: root.title
                font.family: QsTheme.Appearance.fontFamily
                font.pixelSize: QsTheme.Appearance.fontSize.m
                font.weight: Font.Medium
                color: QsTheme.Theme.text
                // 末尾に識別情報が来る名前（"... Input 1 Mic" 等）があるため中間を省く
                elide: Text.ElideMiddle
                visible: text !== ""
            }

            Text {
                Layout.fillWidth: true
                text: root.description
                font.family: QsTheme.Appearance.fontFamily
                font.pixelSize: root.size === "xs" ? QsTheme.Appearance.fontSize.xs : QsTheme.Appearance.fontSize.s
                color: QsTheme.Theme.textVariant
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        Item {
            id: actionsSlot

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
            visible: children.length > 0
        }
    }
}
