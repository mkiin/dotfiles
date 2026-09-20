import QtQuick 6.10
import "../theme" as QsTheme

// 動きの既定値。Behavior の中に置いて使う。
// 速さは fast / normal / slow から選び、曲線は共通。
NumberAnimation {
    id: root

    // fast | normal | slow
    property string speed: "normal"

    duration: QsTheme.Appearance.animDuration[root.speed]
    easing.bezierCurve: QsTheme.Appearance.animCurve.standard
}
