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
    // screen を固定すると mode.sh のモニター切替で出力が一瞬ゼロになった時に
    // サーフェスごと消え、inhibited=true のまま抑制が効かなくなる。Variants で
    // 全出力に張り、出力の抜き差しに追従して張り直す。
    Variants {
        model: Quickshell.screens

        // Overlay 層はフルスクリーン中もマップされたままになる。入力マスクは空。
        PanelWindow {
            id: inhibitWindow

            required property var modelData
            // Hyprland は layer の map 時に inhibitor を再評価しないため、map と
            // 同時に張ると無視される。マップ後に enabled を立て直す。
            property bool armed: false

            screen: modelData
            visible: true
            exclusionMode: ExclusionMode.Ignore
            anchors.top: true
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            mask: Region {}
            QsWl.WlrLayershell.layer: QsWl.WlrLayer.Overlay

            Timer {
                interval: 200
                running: true
                onTriggered: inhibitWindow.armed = true
            }

            QsWl.IdleInhibitor {
                enabled: root.inhibited && inhibitWindow.armed
                window: inhibitWindow
            }
        }
    }
}
