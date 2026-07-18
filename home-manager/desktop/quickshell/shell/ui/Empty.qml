import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../theme" as QsTheme

// 一覧が空のときの表示。アイコン / title / description / content を中央に縦積みする。
Item {
    id: root

    // default | icon （icon はアイコンを角丸の面に載せる）
    property string variant: "default"

    property string icon
    property string title
    property string description

    // 操作を置くスロット（再試行ボタンなど）
    property alias content: contentSlot.data

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight + QsTheme.Appearance.padding.xl * 2

    ColumnLayout {
        id: column

        anchors.centerIn: parent
        width: parent.width
        spacing: QsTheme.Appearance.spacing.s

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: QsTheme.Appearance.spacing.xs
            implicitWidth: 40
            implicitHeight: 40
            radius: QsTheme.Appearance.radius.s
            color: root.variant === "icon" ? QsTheme.Theme.cardHigh : "transparent"
            visible: root.icon !== ""

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: QsTheme.Appearance.iconFamily
                font.pixelSize: QsTheme.Appearance.fontSize.xl
                color: QsTheme.Theme.textVariant
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            font.family: QsTheme.Appearance.fontFamily
            font.pixelSize: QsTheme.Appearance.fontSize.l
            font.weight: Font.Medium
            color: QsTheme.Theme.text
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: text !== ""
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            font.family: QsTheme.Appearance.fontFamily
            font.pixelSize: QsTheme.Appearance.fontSize.m
            color: QsTheme.Theme.textVariant
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: text !== ""
        }

        Item {
            id: contentSlot
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: QsTheme.Appearance.spacing.s
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
            visible: children.length > 0
        }
    }
}
