import QtQuick 6.10
import QtQuick.Controls 6.10
import "../../../components/effects"
import "../../../config" as QsConfig

Slider {
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
        radius: 15
        color: QsConfig.Theme.withAlpha(QsConfig.Theme.text, 0.08)

        Rectangle {
            width: control.position * parent.width
            height: parent.height
            radius: 15
            color: QsConfig.Theme.accent

            Behavior on width {
                NumberAnimation {
                    duration: Material3Anim.short2
                    easing.bezierCurve: Material3Anim.standard
                }
            }
        }

        Rectangle {
            width: 10
            height: 10
            radius: 5
            x: Math.max(0, Math.min(parent.width - width, control.position * parent.width - width / 2))
            y: (parent.height - height) / 2
            color: QsConfig.Theme.accent
            border.width: 2
            border.color: control.surfaceColor
        }
    }

    handle: Rectangle {
        visible: false
    }
}
