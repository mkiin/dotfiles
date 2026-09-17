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

    // 部品の寸法。内容量で変わらず、設計で決める値だけを置く。
    // 中身から決まる高さ（Item / Card / MediaCard 等）はここに持たない。
    readonly property var size: QtObject {
        readonly property var button: QtObject {
            property int sm: 28
            property int normal: 36
            property int lg: 44
        }

        readonly property var switchTrack: QtObject {
            readonly property var sm: QtObject {
                property int width: 24
                property int height: 14
            }
            readonly property var normal: QtObject {
                property int width: 32
                property int height: 18
            }
        }

        readonly property var slider: QtObject {
            readonly property var sm: QtObject {
                property int track: 4
                property int thumb: 12
            }
            readonly property var normal: QtObject {
                property int track: 6
                property int thumb: 16
            }
        }

        // 空状態のアイコンを載せる角丸
        property int emptyIcon: 40
        // ポップアップのヘッダーに置くアイコンの角丸
        property int headerIcon: 36
    }

    // 浮いた面の影。
    readonly property var shadow: QtObject {
        property real opacity: 0.35
        property real blur: 1.0
        property real offsetY: 6
        // 影が面の外へ広がる幅。MultiEffect の blurMax(既定 32)と offsetY を包める大きさ。
        // 面と同じ大きさの窓に影を落とすときは、この分だけ窓を広げないと端で切れる。
        property int margin: 40
    }

    // 画面ごとの寸法。
    readonly property var popup: QtObject {
        property int audioWidth: 320
        property int bluetoothWidth: 320
        property int controlCenterWidth: 420
        property int toastWidth: 360
        // クイック操作タイルの高さ
        property int tileHeight: 72
        // 通知リストが最低限確保する高さと、内部スクロールに切り替わる高さ
        property int notificationMinHeight: 160
        property int notificationMaxHeight: 360
    }

    // 画面端との隙間。waybar の島と縦のラインを揃える（style.nix の gapIsland と同値）。
    readonly property int edgeGap: 6
}
