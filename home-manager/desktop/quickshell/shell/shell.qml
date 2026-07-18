//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Io
import QtQuick
import "theme" as QsTheme
import "windows"
import "features/notifications" as QsNotifications
import "features/power" as QsPower

// 常駐デーモン。
//
// TODO: UI を作り直し中。windows/ と一部の features/ が未実装のため、
// 通知サーバ・各ウィンドウ・IPC の大半をコメントアウトしている。
// 生きているのは matugen のカラーリロードのみ。
ShellRoot {
    id: root

    // TODO: features/notifications の実装後に戻す
    // readonly property var notifs: QsNotifications.Notifs

    // TODO: windows/ の実装後に戻す。パネルは同時に 1 つだけ開く
    // function openPanel(name: string): void {
    //     const next = { cc: ccPopout.shouldShow, audio: audioPopout.shouldShow, bluetooth: bluetoothPopout.shouldShow }[name]
    //     ccPopout.shouldShow = false
    //     audioPopout.shouldShow = false
    //     bluetoothPopout.shouldShow = false
    //     if (name === "cc") ccPopout.shouldShow = !next
    //     else if (name === "audio") audioPopout.shouldShow = !next
    //     else if (name === "bluetooth") bluetoothPopout.shouldShow = !next
    // }

    // TODO: org.freedesktop.Notifications を所有してアプリ通知を受ける。
    // 受け皿となる通知状態の層が無いので止めている。
    // Loader {
    //     active: Config.registerNotificationServer
    //     sourceComponent: NotificationServer {
    //         keepOnReload: false
    //         actionsSupported: true
    //         bodyHyperlinksSupported: true
    //         bodyMarkupSupported: true
    //         imageSupported: true
    //         persistenceSupported: true
    //
    //         onNotification: notif => {
    //             notif.tracked = true
    //             root.notifs.addNotification(notif)
    //         }
    //     }
    // }

    // TODO: windows/ の実装後に戻す
    // QsCC.ControlCenterWindow {
    //     id: ccPopout
    //     shouldShow: false
    // }
    //
    // AudioPopout {
    //     id: audioPopout
    //     shouldShow: false
    // }
    //
    // BluetoothPopout {
    //     id: bluetoothPopout
    //     shouldShow: false
    // }

    // TODO: waybar のオーディオ/Bluetooth アイコンからのトグル
    // IpcHandler {
    //     target: "audio"
    //     function toggle(): void { root.openPanel("audio") }
    // }
    //
    // IpcHandler {
    //     target: "bluetooth"
    //     function toggle(): void { root.openPanel("bluetooth") }
    // }

    // TODO: waybar / Super+N からのトグルと、通知アイコン用の JSON。
    // waybar 側の format-icons / CSS は none / notification / dnd-none / dnd-notification の
    // 4 状態に整理済みなので、alt と class は同じ 4 値を返すこと。
    // IpcHandler {
    //     target: "cc"
    //     function toggle(): void { root.openPanel("cc") }
    //     function status(): string {
    //         const unread = root.notifs.unreadCount
    //         const dnd = root.notifs.dnd
    //         const alt = (dnd ? "dnd-" : "") + (unread > 0 ? "notification" : "none")
    //         return JSON.stringify({ text: "", alt: alt, class: alt, tooltip: (dnd ? "DND · " : "") + unread + " unread" })
    //     }
    // }

    BluetoothPopout {
        id: bluetoothPopout
        shouldShow: false
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void {
            bluetoothPopout.shouldShow = !bluetoothPopout.shouldShow;
        }
    }

    // waybar の通知アイコン。alt と class は none / notification / dnd-none / dnd-notification の 4 値。
    IpcHandler {
        target: "cc"
        function status(): string {
            const unread = QsNotifications.Notifs.unreadCount;
            const dnd = QsNotifications.Notifs.dnd;
            const alt = (dnd ? "dnd-" : "") + (unread > 0 ? "notification" : "none");
            return JSON.stringify({
                text: "",
                alt: alt,
                class: alt,
                tooltip: (dnd ? "DND · " : "") + unread + " unread"
            });
        }
    }

    // waybar のアイドルインヒビター表示
    IpcHandler {
        target: "idle"
        function status(): string {
            const inhibited = QsPower.IdleInhibitor.inhibited;
            return JSON.stringify({
                text: inhibited ? "󰈈" : "󰈉",
                class: inhibited ? "activated" : "deactivated",
                tooltip: inhibited ? "Idle inhibited (caffeine on)" : "Idle inhibitor off"
            });
        }
    }

    // 壁紙変更後に matugen post_hook から呼ぶカラーリロード
    IpcHandler {
        target: "theme"
        function reload(): void {
            QsTheme.Colours.reload();
        }
    }

    // TODO: waybar のアイドルインヒビター表示。切り替えは Control Center から行う。
    // IpcHandler {
    //     target: "idle"
    //     function status(): string {
    //         const inhibited = QsPower.IdleInhibitor.inhibited
    //         return JSON.stringify({
    //             text: inhibited ? "󰈈" : "󰈉",
    //             class: inhibited ? "activated" : "deactivated",
    //             tooltip: inhibited ? "Idle inhibited (caffeine on)" : "Idle inhibitor off"
    //         })
    //     }
    // }
}
