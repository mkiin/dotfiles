pragma Singleton

import Quickshell
import QtQuick

// 寸法・タイポ・アニメの単一情報源。サイズ語彙は xs/s/m/l/xl/full。
// 色は Theme、環境依存値は Config が持つ（このファイルには置かない）。
Singleton {
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

    readonly property var typography: QtObject {
        property string family: Config.appearance.fontFamily
        property string iconFamily: Config.appearance.materialIconFont

        readonly property var displaySmall: QtObject { property int size: 36; property int weight: Font.Normal }
        readonly property var headlineLarge: QtObject { property int size: 32; property int weight: Font.Normal }
        readonly property var headlineMedium: QtObject { property int size: 28; property int weight: Font.Normal }
        readonly property var headlineSmall: QtObject { property int size: 24; property int weight: Font.Normal }
        readonly property var titleLarge: QtObject { property int size: 22; property int weight: Font.Normal }
        readonly property var titleMedium: QtObject { property int size: 16; property int weight: Font.Medium }
        readonly property var labelMedium: QtObject { property int size: 12; property int weight: Font.Medium }
        readonly property var labelSmall: QtObject { property int size: 11; property int weight: Font.Medium }
        readonly property var bodyLarge: QtObject { property int size: 16; property int weight: Font.Normal }
        readonly property var bodyMedium: QtObject { property int size: 14; property int weight: Font.Normal }
    }

    // M3 の duration トークンと、本設定で先に使っていた 4 種が併存する。
    // 新規コードは M3 側（short2/short3/short4/medium2/medium4）を使う。
    readonly property var anim: QtObject {
        readonly property var durations: QtObject {
            property int fast: 120
            property int normal: 180
            property int medium: 260
            property int slow: 340

            property int short2: 100
            property int short3: 150
            property int short4: 200
            property int medium2: 300
            property int medium4: 400
        }
        readonly property var curves: QtObject {
            property var standard: [0.2, 0.0, 0, 1.0]
            property var standardDecel: [0.0, 0.0, 0, 1.0]
            property var standardAccel: [0.3, 0.0, 1, 1.0]
            property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0]
            property var emphasizedAccel: [0.3, 0.0, 0.8, 0.15]
            property var springGentle: [0.22, 1.0, 0.36, 1.0]
        }
        readonly property real hoverScale: 1.02
    }

    // バー直下に出るフローティングパネル（CC / popouts）共通の画面配置
    readonly property var panel: QtObject {
        property int barOffset: 40 // waybar 下端（モニタ上端から px）
        property int edgeGap: 8 // 画面端との隙間。waybar の外周ギャップと揃える
    }

    readonly property var alpha: QtObject {
        property real hover: 0.06
        property real border: 0.08
        property real low: 0.14
        property real medium: 0.42
        property real high: 0.68
        property real full: 1.0
    }
}
