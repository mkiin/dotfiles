//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import QtQuick
import "theme" as QsTheme
import "features/notifications" as QsNotifications
import "features/power" as QsPower
import "config" as QsConfig
import "windows/controlcenter" as QsCC
import "windows"

// 常駐デーモン: 通知サーバ ＋ トースト ＋ 通知センター(ControlCenter) ＋ audio/bluetooth ポップアウト。
ShellRoot {
    id: root

    readonly property var notifs: QsNotifications.Notifs

    // パネルは同時に 1 つだけ開く（別プロセス時代は重なりが起きていた）
    function openPanel(name: string): void {
        const next = { cc: cc.shouldShow, audio: audioPopout.shouldShow, bluetooth: bluetoothPopout.shouldShow }[name]
        cc.shouldShow = false
        audioPopout.shouldShow = false
        bluetoothPopout.shouldShow = false
        if (name === "cc") cc.shouldShow = !next
        else if (name === "audio") audioPopout.shouldShow = !next
        else if (name === "bluetooth") bluetoothPopout.shouldShow = !next
    }

    // org.freedesktop.Notifications を所有してアプリ通知を受ける
    Loader {
        active: QsConfig.Config.notifications.registerServer
        sourceComponent: NotificationServer {
            keepOnReload: false
            actionsSupported: true
            bodyHyperlinksSupported: true
            bodyMarkupSupported: true
            imageSupported: true
            persistenceSupported: true

            onNotification: notif => {
                notif.tracked = true
                root.notifs.addNotification(notif)
            }
        }
    }

    // 通知センター本体（クイックトグル/スライダ/MPRIS/通知リスト/電源）
    QsCC.ControlCenterWindow {
        id: cc
        shouldShow: false
    }

    AudioPopout {
        id: audioPopout
        shouldShow: false
    }

    BluetoothPopout {
        id: bluetoothPopout
        shouldShow: false
    }

    // waybar のオーディオ/Bluetooth アイコンからのトグル
    IpcHandler {
        target: "audio"
        function toggle(): void { root.openPanel("audio") }
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void { root.openPanel("bluetooth") }
    }

    // waybar / Super+N からのトグル
    IpcHandler {
        target: "cc"
        function toggle(): void { root.openPanel("cc") }
        function open(): void { cc.shouldShow = false; root.openPanel("cc") }
        function close(): void { cc.shouldShow = false }
        function dnd(): void { root.notifs.toggleDnd() }
        // waybar custom モジュール互換 JSON（alt で format-icons を選択）
        function status(): string {
            const unread = root.notifs.unreadCount
            const dnd = root.notifs.dnd
            const alt = (dnd ? "dnd-" : "") + (unread > 0 ? "notification" : "none")
            return JSON.stringify({ text: "", alt: alt, tooltip: (dnd ? "DND · " : "") + unread + " unread" })
        }
    }

    // 壁紙変更後に matugen post_hook から呼ぶカラーリロード
    IpcHandler {
        target: "theme"
        function reload(): void { QsTheme.Colours.reload() }
    }

    // アイドルインヒビター(Caffeine)を waybar と共有。状態の真実はこの IdleInhibitor サービス。
    IpcHandler {
        target: "idle"
        function toggle(): void { QsPower.IdleInhibitor.inhibited = !QsPower.IdleInhibitor.inhibited }
        function status(): string {
            const inhibited = QsPower.IdleInhibitor.inhibited
            return JSON.stringify({
                text: inhibited ? "󰈈" : "󰈉",
                class: inhibited ? "activated" : "deactivated",
                tooltip: inhibited ? "Idle inhibited (caffeine on)" : "Idle inhibitor off"
            })
        }
    }
}
