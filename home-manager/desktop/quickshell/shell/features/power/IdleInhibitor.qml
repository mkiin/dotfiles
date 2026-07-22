pragma Singleton

import Quickshell
import Quickshell.Wayland as QsWl
import QtQuick

// アイドル抑制（Caffeine）。
// systemd-inhibit --what=idle は logind にしか効かず、hypridle の listener は
// Wayland の idle-notify で動くため止まらない。zwp_idle_inhibit を可視サーフェスに
// 張れば Hyprland が通知自体を止めるので、hypridle の inhibit カウンタ
// （外部アプリの解除バグで壊れる）にも依存しない。
Singleton {
    id: root

    property bool inhibited: false

    function toggle(): void {
        root.inhibited = !root.inhibited;
    }

    // プロトコル上、抑制には可視サーフェスが必要なので 1px の透明ウィンドウを張る。
    // Hyprland は layer の map 時に inhibitor を再評価しないため、トグル時に
    // ウィンドウごと出すと未マップのまま登録されて無視されるレースがある。
    // 常時マップしておき enabled だけを切り替えることでこれを避ける。
    // Overlay 層はフルスクリーン中もマップされたままになる。入力マスクは空。
    PanelWindow {
        id: inhibitWindow

        visible: true
        exclusionMode: ExclusionMode.Ignore
        anchors.top: true
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        mask: Region {}
        QsWl.WlrLayershell.layer: QsWl.WlrLayer.Overlay

        QsWl.IdleInhibitor {
            enabled: root.inhibited
            window: inhibitWindow
        }
    }
}
