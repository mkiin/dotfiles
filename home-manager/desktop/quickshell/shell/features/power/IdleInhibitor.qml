pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// アイドル抑制（Caffeine）。
// systemd-inhibit を running に束縛するだけで、プロセスの寿命は quickshell と一致する。
// PID の記録や pkill による後始末は要らない。
Singleton {
    id: root

    property bool inhibited: false

    function toggle(): void {
        root.inhibited = !root.inhibited;
    }

    Process {
        running: root.inhibited
        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=Caffeine", "sleep", "infinity"]
    }
}
