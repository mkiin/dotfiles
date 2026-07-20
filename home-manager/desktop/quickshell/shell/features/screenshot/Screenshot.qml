pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

// 撮影・録画の実装は hyprland/scripts/{screenshot,record}.sh が正。
// ここはキーバインド・rofi と同じスクリプトを呼ぶだけの薄い層。
Singleton {
    id: root

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    // record.sh が作る PID ファイルの有無が録画状態。
    // キーバインドから停止されてもファイル監視で拾える。
    readonly property bool isRecording: pidFile.exists

    property bool recorderAvailable: false

    function takeScreenshot(mode: string): void {
        // CC の "screen" はスクリプトの "output"（フォーカス中モニタ全体）
        const target = mode === "screen" ? "output" : mode;
        Quickshell.execDetached([`${root.scriptsDir}/screenshot.sh`, target]);
    }

    // rofi の region/window/output 選択メニュー（Super+P と同じ入口）
    function openMenu(): void {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/rofi/screenshot-menu.sh"]);
    }

    // record.sh は呼ぶたびに開始と停止が切り替わる。
    function toggleRecording(): void {
        recordProc.running = true;
    }

    Process {
        id: recordProc
        command: [`${root.scriptsDir}/record.sh`]
    }

    Process {
        id: probeProc
        command: ["which", "gpu-screen-recorder"]
        onExited: code => root.recorderAvailable = (code === 0)
    }

    FileView {
        id: pidFile

        property bool exists: false

        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/gpu-screen-recorder.pid"
        watchChanges: true
        onLoaded: pidFile.exists = true
        onFileChanged: pidFile.reload()
        onLoadFailed: pidFile.exists = false
    }

    Component.onCompleted: probeProc.running = true
}
