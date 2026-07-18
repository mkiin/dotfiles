import QtQuick 6.10
import QtQuick.Templates 6.10 as T
import "../theme" as QsTheme

// 見た目は variant、寸法は size、形は iconOnly で切り替える。3 つは直交する。
// 状態(hovered/pressed/checked)と入力は Templates が持つ。
T.Button {
    id: root

    // default | outline | secondary | ghost | destructive
    property string variant: "default"
    // sm | default | lg
    property string size: "default"
    // true なら正方形の円形ボタンになり、text をアイコン書体で描く
    property bool iconOnly: false

    readonly property var palette: ({
            default: {
                surface: QsTheme.Theme.primary,
                hover: QsTheme.Theme.primaryContainer,
                foreground: QsTheme.Theme.onPrimary
            },
            outline: {
                surface: "transparent",
                hover: QsTheme.Theme.cardHigh,
                foreground: QsTheme.Theme.text
            },
            secondary: {
                surface: QsTheme.Theme.secondaryContainer,
                hover: QsTheme.Theme.secondary,
                foreground: QsTheme.Theme.onSecondaryContainer
            },
            ghost: {
                surface: "transparent",
                hover: QsTheme.Theme.cardHigh,
                foreground: QsTheme.Theme.text
            },
            destructive: {
                surface: QsTheme.Theme.errorContainer,
                hover: QsTheme.Theme.error,
                foreground: QsTheme.Theme.onErrorContainer
            }
        })[root.variant]

    // 高さ。iconOnly なら 1 辺の長さも兼ねる。
    readonly property int extent: ({
            sm: 28,
            default: 36,
            lg: 44
        })[root.size]

    hoverEnabled: true
    implicitWidth: root.iconOnly ? root.extent : implicitContentWidth + leftPadding + rightPadding
    implicitHeight: root.extent
    padding: root.iconOnly ? 0 : QsTheme.Appearance.padding.m
    opacity: root.enabled ? 1 : 0.5

    background: Rectangle {
        radius: root.iconOnly ? height / 2 : QsTheme.Appearance.radius.s
        color: root.hovered ? root.palette.hover : root.palette.surface
        border.width: root.variant === "outline" ? 1 : 0
        border.color: QsTheme.Theme.border
    }

    contentItem: Text {
        text: root.text
        font.family: root.iconOnly ? QsTheme.Appearance.iconFamily : QsTheme.Appearance.fontFamily
        font.pixelSize: QsTheme.Appearance.fontSize.m
        font.weight: Font.Medium
        color: root.palette.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
