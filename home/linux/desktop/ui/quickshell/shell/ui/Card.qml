import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../theme" as QsTheme

// 情報のまとまりを囲う面。header / content / footer の 3 スロットを縦に積む。
// 余白は size が決め、スロット間の間隔にも同じ値を使う。
Rectangle {
    id: root

    // sm | default
    property string size: "default"

    property alias header: headerSlot.data
    property alias content: contentSlot.data
    property alias footer: footerSlot.data

    readonly property int gap: root.size === "sm" ? QsTheme.Appearance.spacing.m : QsTheme.Appearance.spacing.l

    implicitWidth: column.implicitWidth + root.gap * 2
    implicitHeight: column.implicitHeight + root.gap * 2

    color: QsTheme.Theme.card
    radius: QsTheme.Appearance.radius.m
    border.width: 1
    border.color: QsTheme.Theme.border
    clip: true

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: root.gap
        spacing: root.gap

        Item {
            id: headerSlot
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            visible: children.length > 0
        }

        Item {
            id: contentSlot
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            visible: children.length > 0
        }

        Item {
            id: footerSlot
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            visible: children.length > 0
        }
    }
}
