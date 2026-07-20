import QtQuick 6.10
import "../theme" as QsTheme

// 面の色を差し替えず、on-color を薄く重ねて hover / pressed を表す。
// 入力も兼ねるので、利用側は clicked を受けるだけでよい。
// 角丸は親から自動で引き継ぐ。
MouseArea {
    id: root

    // 重ねる色。面の色に対応する on-color を渡す。
    property color color: QsTheme.Theme.text

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

    Rectangle {
        anchors.fill: parent
        color: root.color
        radius: root.parent?.radius ?? 0

        opacity: {
            if (!root.enabled)
                return 0;
            if (root.pressed)
                return QsTheme.Theme.statePressed;
            if (root.containsMouse)
                return QsTheme.Theme.stateHovered;
            return 0;
        }

        // 行の隙間を通るたびに点滅しないよう、状態変化に時間をかける。
        Behavior on opacity {
            Anim {
                speed: "fast"
            }
        }
    }
}
