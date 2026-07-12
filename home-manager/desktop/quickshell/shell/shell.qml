//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import QtQuick
import "services" as QsServices
import "config" as QsConfig
import "modules/controlcenter"

// 常駐デーモン: 通知サーバ ＋ トースト ＋ 通知センター(ControlCenter)。
ShellRoot {
    id: root

    readonly property var notifs: QsServices.Notifs

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

    // トースト（右上）
    Loader {
        source: "modules/notifications/NotificationPopups.qml"
    }

    // 通知センター本体（クイックトグル/スライダ/MPRIS/通知リスト/電源）
    ControlCenterWindow {
        id: cc
        shouldShow: false
    }

    // waybar / Super+N からのトグル
    IpcHandler {
        target: "cc"
        function toggle(): void { cc.shouldShow = !cc.shouldShow }
        function open(): void { cc.shouldShow = true }
        function close(): void { cc.shouldShow = false }
        function dnd(): void { root.notifs.toggleDnd() }
        // waybar custom モジュール互換 JSON（alt で format-icons を選択）
        function status(): string {
            const u = root.notifs.unreadCount
            const d = root.notifs.dnd
            const alt = (d ? "dnd-" : "") + (u > 0 ? "notification" : "none")
            return JSON.stringify({ text: "", alt: alt, tooltip: (d ? "DND · " : "") + u + " unread" })
        }
    }

    // 壁紙変更後に matugen post_hook から呼ぶカラーリロード
    IpcHandler {
        target: "theme"
        function reload(): void { QsServices.Pywal.reload() }
    }

    // アイドルインヒビター(Caffeine)を waybar と共有。状態の真実はこの IdleInhibitor サービス。
    IpcHandler {
        target: "idle"
        function toggle(): void { QsServices.IdleInhibitor.inhibited = !QsServices.IdleInhibitor.inhibited }
        function status(): string {
            const on = QsServices.IdleInhibitor.inhibited
            return JSON.stringify({
                text: on ? "󰈈" : "󰈉",
                class: on ? "activated" : "deactivated",
                tooltip: on ? "Idle inhibited (caffeine on)" : "Idle inhibitor off"
            })
        }
    }
}
