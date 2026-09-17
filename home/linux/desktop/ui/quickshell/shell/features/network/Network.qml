pragma Singleton

import Quickshell
import QtQuick

// TODO: Wi-Fi は現在未使用のスタブ。CC のタイルを描くための最小限のみ。
// 実際に使うときは nmcli monitor で変化を検知する実装に置き換える。
Singleton {
    readonly property bool wifiEnabled: false
    readonly property bool connected: false
    readonly property string ssid: ""

    function toggleWifi(): void {}
}
