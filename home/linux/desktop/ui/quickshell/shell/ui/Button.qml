import QtQuick 6.10
import "../theme" as QsTheme

// 見た目は variant、寸法は size、形は iconOnly で切り替える。3 つは直交する。
// hover / pressed の表現と入力は StateLayer が担う。
Rectangle {
    id: root

    // default | outline | secondary | ghost | destructive
    property string variant: "default"
    // sm | default | lg
    property string size: "default"
    // true なら正方形の円形ボタンになり、text をアイコン書体で描く
    property bool iconOnly: false

    property string text

    signal clicked

    // 面と、その上に乗る on-color の組。
    readonly property var palette: ({
            default: {
                surface: QsTheme.Theme.primary,
                onSurface: QsTheme.Theme._onPrimary
            },
            outline: {
                surface: "transparent",
                onSurface: QsTheme.Theme.text
            },
            secondary: {
                surface: QsTheme.Theme.secondaryContainer,
                onSurface: QsTheme.Theme._onSecondaryContainer
            },
            ghost: {
                surface: "transparent",
                onSurface: QsTheme.Theme.text
            },
            destructive: {
                surface: QsTheme.Theme.errorContainer,
                onSurface: QsTheme.Theme._onErrorContainer
            }
        })[root.variant]

    // 高さ。iconOnly なら 1 辺の長さも兼ねる。
    readonly property int extent: ({
            sm: QsTheme.Appearance.size.button.sm,
            default: QsTheme.Appearance.size.button.normal,
            lg: QsTheme.Appearance.size.button.lg
        })[root.size]

    implicitWidth: root.iconOnly ? root.extent : label.implicitWidth + QsTheme.Appearance.padding.m * 2
    implicitHeight: root.extent

    color: root.palette.surface
    radius: root.iconOnly ? height / 2 : QsTheme.Appearance.radius.s
    border.width: root.variant === "outline" ? 1 : 0
    border.color: QsTheme.Theme.border
    opacity: root.enabled ? 1 : 0.5

    Text {
        id: label

        anchors.centerIn: parent
        width: root.iconOnly ? parent.width : parent.width - QsTheme.Appearance.padding.m * 2
        text: root.text
        font.family: root.iconOnly ? QsTheme.Appearance.iconFamily : QsTheme.Appearance.fontFamily
        font.pixelSize: QsTheme.Appearance.fontSize.m
        font.weight: Font.Medium
        color: root.palette.onSurface
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    StateLayer {
        color: root.palette.onSurface
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
