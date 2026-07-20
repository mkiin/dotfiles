pragma Singleton

import Quickshell
import QtQuick
import ".." as QsRoot

// 寸法とタイポの階段。いずれも意味を持たない大きさの序列で、
// 何を表す要素かは使う側が組み合わせで表現する。
// 色は Theme、環境依存値は Config が持つ。
Singleton {
    id: root

    readonly property var radius: QtObject {
        property int xs: 6
        property int s: 10
        property int m: 16
        property int l: 22
        property int xl: 32
        property int full: 9999
    }

    readonly property var spacing: QtObject {
        property int xs: 4
        property int s: 8
        property int m: 12
        property int l: 16
        property int xl: 24
    }

    readonly property var padding: QtObject {
        property int xs: 4
        property int s: 8
        property int m: 12
        property int l: 16
        property int xl: 22
    }

    readonly property var margin: QtObject {
        property int xs: 6
        property int s: 10
        property int m: 14
        property int l: 20
        property int xl: 28
    }

    readonly property string fontFamily: QsRoot.Config.fontFamily
    readonly property string iconFamily: QsRoot.Config.iconFamily

    readonly property var fontSize: QtObject {
        property int xs: 11
        property int s: 12
        property int m: 14
        property int l: 16
        property int xl: 32
    }

    // 動きの時間と曲線。ui/Anim が参照する。
    readonly property var animDuration: QtObject {
        property int fast: 100
        property int normal: 200
        property int slow: 300
    }

    readonly property var animCurve: QtObject {
        // M3 の standard。減速して止まる。
        property var standard: [0.2, 0.0, 0.0, 1.0]
    }

    // 画面端との隙間。waybar の島と縦のラインを揃える（style.nix の gapIsland と同値）。
    readonly property int edgeGap: 6
}
