import QtQuick 6.10
import QtQuick.Controls 6.10 as QQC
import "../../../theme" as QsTheme

QQC.Slider {
    id: control

    property color surfaceColor
    property real wheelStep: 1

    // ホイールでの増減（0〜100 にクランプ済みの新しい値を渡す）
    signal volumeStepped(real newValue)

    from: 0
    to: 100
    live: true

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const dir = wheel.angleDelta.y > 0 ? 1 : -1
            control.volumeStepped(Math.max(0, Math.min(100, control.value + dir * control.wheelStep)))
        }
    }

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 30
        width: control.availableWidth
        height: implicitHeight
        radius: height / 2
        color: QsTheme.Theme.cardHigh

        Rectangle {
            width: control.position * parent.width
            height: parent.height
            radius: height / 2
            color: QsTheme.Theme.primary

            Behavior on width {
                NumberAnimation {
                    duration: QsTheme.Appearance.anim.durations.short2
                    easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
                }
            }
        }

        Rectangle {
            width: 10
            height: 10
            radius: height / 2
            x: Math.max(0, Math.min(parent.width - width, control.position * parent.width - width / 2))
            y: (parent.height - height) / 2
            color: QsTheme.Theme.primary
            border.width: 2
            border.color: control.surfaceColor
        }
    }

    handle: Rectangle {
        visible: false
    }
}
