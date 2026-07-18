import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Templates 6.10 as T
import "../theme" as QsTheme

// 一覧の 1 行。左(media) / 中央(title + description) / 右(actions) の 3 スロット。
// クリック可能な行として使えるよう ItemDelegate を土台にする。
T.ItemDelegate {
    id: root

    // default | outline | muted
    property string variant: "default"
    // xs | sm | default
    property string size: "default"

    property string title
    property string description

    // 左右のスロット。Item を渡すと配置される。
    property alias media: mediaSlot.data
    property alias actions: actionsSlot.data

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

    hoverEnabled: true
    leftPadding: root.padX
    rightPadding: root.padX
    topPadding: root.padY
    bottomPadding: root.padY
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding
    opacity: root.enabled ? 1 : 0.5

    background: Rectangle {
        radius: QsTheme.Appearance.radius.s
        color: root.hovered ? QsTheme.Theme.cardHigh : (root.variant === "muted" ? QsTheme.Theme.card : "transparent")
        border.width: root.variant === "outline" ? 1 : 0
        border.color: QsTheme.Theme.border
    }

    contentItem: RowLayout {
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
                elide: Text.ElideRight
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

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
