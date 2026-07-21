//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "theme" as QsTheme
import "windows"
import "windows/controlcenter" as QsCC
import "features/notifications" as QsNotifications
import "features/power" as QsPower

// 常駐デーモン。通知サーバと IPC の配線のみ。
ShellRoot {
    id: root

    // パネルは同時に 1 つだけ開く
    function openPanel(name: string): void {
        const next = {
            cc: ccPopout.shouldShow,
            audio: audioPopout.shouldShow,
            bluetooth: bluetoothPopout.shouldShow
        }[name];
        ccPopout.shouldShow = false;
        audioPopout.shouldShow = false;
        bluetoothPopout.shouldShow = false;
        if (name === "cc")
            ccPopout.shouldShow = !next;
        else if (name === "audio")
            audioPopout.shouldShow = !next;
        else if (name === "bluetooth")
            bluetoothPopout.shouldShow = !next;
    }

    // org.freedesktop.Notifications を所有してアプリ通知を受ける
    NotificationServer {
        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;
            QsNotifications.Notifs.addNotification(notif);
        }
    }

    QsCC.ControlCenterWindow {
        id: ccPopout
        shouldShow: false
    }

    BluetoothPopout {
        id: bluetoothPopout
        shouldShow: false
    }

    AudioPopout {
        id: audioPopout
        shouldShow: false
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void {
            root.openPanel("bluetooth");
        }
    }

    IpcHandler {
        target: "audio"
        function toggle(): void {
            root.openPanel("audio");
        }
    }

    // waybar の通知アイコン。alt と class は none / notification / dnd-none / dnd-notification の 4 値。
    IpcHandler {
        target: "cc"
        function toggle(): void {
            root.openPanel("cc");
        }
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
}
