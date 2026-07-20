pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Services.Notifications
import "../../utils" as QsUtils

// 通知の履歴と既読状態。値は元の Notification が持つので、ここでは包んで束ねるだけ。
Singleton {
    id: root

    // 保持上限。超えた分は古いものから捨てる。
    readonly property int maxNotifications: 100
    // 履歴に残す期間
    readonly property int retentionHours: 24

    property var notifications: []

    // 経過時間の表示を更新するための時計。各通知はこれを参照して再計算する。
    property date now: new Date()

    property bool dnd: false
    property double lastReadAt: 0

    readonly property var recentNotifications: root.notifications.filter(notif => notif && notif.withinRetention).sort((left, right) => right.timestamp.getTime() - left.timestamp.getTime())

    readonly property int unreadCount: root.recentNotifications.filter(notif => !notif.read).length

    PersistentProperties {
        id: persist

        property alias dnd: root.dnd
        property alias lastReadAt: root.lastReadAt

        reloadableId: "notifications-state"
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    // NotificationServer から渡された通知を履歴に加える。
    function addNotification(notification): void {
        if (root.dnd && notification.urgency !== NotificationUrgency.Critical)
            return;

        const wrapper = notifComponent.createObject(root, {
            notification: notification
        });
        if (!wrapper) {
            QsUtils.Logger.error("Notifs", "Failed to create notification wrapper");
            return;
        }

        root.notifications = [wrapper, ...root.notifications].slice(0, root.maxNotifications);
    }

    // 既読の境界を進める。個々の read はこの値から導出される。
    function markAllRead(): void {
        root.lastReadAt = Date.now();
    }

    function toggleDnd(): void {
        root.dnd = !root.dnd;
    }

    function clearAll(): void {
        const all = root.notifications;
        root.notifications = [];
        all.forEach(notif => notif?.destroy());
    }

    function remove(notif): void {
        if (!root.notifications.includes(notif))
            return;
        root.notifications = root.notifications.filter(other => other !== notif);
        notif.destroy();
    }

    // 通知 1 件。元の Notification を包み、表示に必要な導出だけを足す。
    component Notif: QtObject {
        id: notif

        required property var notification

        readonly property date timestamp: new Date()

        readonly property string summary: notif.notification?.summary ?? ""
        readonly property string body: notif.notification?.body ?? ""
        readonly property string appName: notif.notification?.appName ?? ""
        readonly property string appIcon: notif.notification?.appIcon ?? ""
        readonly property string image: notif.notification?.image ?? ""
        readonly property int urgency: notif.notification?.urgency ?? NotificationUrgency.Normal
        readonly property var actions: notif.notification?.actions ?? []

        // 既読かどうかは境界時刻との比較で決まる。個別のフラグは持たない。
        readonly property bool read: notif.timestamp.getTime() <= root.lastReadAt

        readonly property bool withinRetention: (root.now.getTime() - notif.timestamp.getTime()) < root.retentionHours * 3600000

        // トーストの出現アニメを 1 度だけ再生するための記録。表示側が立てる。
        property bool hasAnimated: false

        readonly property string timeString: {
            const minutes = Math.floor((root.now.getTime() - notif.timestamp.getTime()) / 60000);
            if (minutes < 1)
                return "Just now";
            if (minutes < 60)
                return `${minutes}m ago`;
            const hours = Math.floor(minutes / 60);
            if (hours < 24)
                return `${hours}h ago`;
            return `${Math.floor(hours / 24)}d ago`;
        }

        function dismiss(): void {
            notif.notification?.dismiss();
        }
    }

    Component {
        id: notifComponent

        Notif {}
    }
}
