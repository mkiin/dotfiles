import QtQuick 6.10
import QtQuick.Templates 6.10 as T

// ヘッドレスなボタン。見た目は持たず、状態と入力だけを提供する。
// 呼び出し側が background / contentItem に好きな見た目を差す。
// hovered / pressed / down / checked は Templates が面倒を見る。
T.Button {
    id: root

    hoverEnabled: true

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, implicitContentHeight + topPadding + bottomPadding)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
    }
}
