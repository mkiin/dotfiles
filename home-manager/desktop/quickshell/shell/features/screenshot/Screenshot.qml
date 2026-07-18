pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick 6.10

// 撮影・録画の実装は hyprland/scripts/{screenshot,record}.sh が正。
// ここはキーバインド・rofi と同じスクリプトを呼ぶだけの薄い層。
Singleton {
    id: root

    // screenshot.sh の base_dir と一致させる（"Open Captures" ボタン用）
    readonly property string screenshotsDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    property bool isRecording: false
    property bool recorderAvailable: false

    function takeScreenshot(mode: string): void {
        // CC の "screen" はスクリプトの "output"（フォーカス中モニタ全体）
        const m = mode === "screen" ? "output" : mode
        Quickshell.execDetached([`${root.scriptsDir}/screenshot.sh`, m])
    }

    // rofi の region/window/output 選択メニュー（Super+P と同じ入口）
    function openMenu(): void {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/rofi/screenshot-menu.sh"])
    }

    // record.sh は呼ぶたびに開始/停止が切り替わるトグル（recorder 本体は script が孤児化させる）
    function startRecording(): void { recordProc.running = true }
    function stopRecording(): void { recordProc.running = true }

    Process {
        id: recordProc
        command: [`${root.scriptsDir}/record.sh`]
        onExited: statusProc.running = true
    }

    Process {
        id: probeProc
        command: ["which", "gpu-screen-recorder"]
        onExited: code => root.recorderAvailable = (code === 0)
    }

    Process {
        id: statusProc
        command: ["sh", "-c", 'f="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.pid"; test -f "$f" && kill -0 "$(cat "$f")"']
        onExited: code => root.isRecording = (code === 0)
    }

    // キーバインド側からの停止も拾うため録画中はポーリング
    Timer {
        interval: 3000
        repeat: true
        running: root.isRecording
        onTriggered: statusProc.running = true
    }

    Component.onCompleted: {
        probeProc.running = true
        statusProc.running = true
    }
}
