pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Services.Notifications
import "../../utils" as QsUtils

// 通知の履歴と既読状態。生きている間は元の Notification に追従し、closed の直前に
// 値を固定して履歴に残す(quickshell は closed 後に元オブジェクトを破棄する)。
Singleton {
    id: root

    // 保持上限。超えた分は古いものから捨てる。
    readonly property int maxNotifications: 100
    // 履歴に残す期間
    readonly property int retentionHours: 24

    // 同時に画面へ出すトーストの数。超えた分は古いものから押し出す。
    readonly property int maxPopups: 3
    // 送り手が表示時間を指定しなかったときの既定値
    readonly property int defaultPopupTimeout: 5000

    property var notifications: []

    // いま画面に出ているもの。履歴とは独立で、畳んでも履歴には残る。
    property var popups: []

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
        // 押し出されたトーストは履歴に残るので destroy しない。
        root.popups = [wrapper, ...root.popups].slice(0, root.maxPopups);
    }

    // トーストを畳み始める。表示側が消える動きを再生し、終えてから removePopup を呼ぶ。
    function dismissPopup(notif): void {
        if (notif)
            notif.dismissing = true;
    }

    // popups から外す。履歴には残る(履歴から消すのは remove)。
    function removePopup(notif): void {
        root.popups = root.popups.filter(other => other !== notif);
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
        root.popups = [];
        all.forEach(notif => {
            notif?.dismiss();
            notif?.destroy();
        });
    }

    function remove(notif): void {
        if (!root.notifications.includes(notif))
            return;
        root.notifications = root.notifications.filter(other => other !== notif);
        root.removePopup(notif);
        // D-Bus 側にも閉じたことを伝える。tracked のまま置き去りにしない。
        notif.dismiss();
        notif.destroy();
    }

    // 通知 1 件。表示用の値と、トーストをいつ消し始めるかという方針だけを持つ。
    // 消える「動き」は表示側の仕事で、ここでは時間も曲線も知らない。
    component Notif: QtObject {
        id: notif

        required property var notification

        readonly property date timestamp: new Date()

        // freeze が束縛を代入で切って最後の値を固定するため、readonly にしない。
        property string summary: notif.notification?.summary ?? ""
        property string body: notif.notification?.body ?? ""
        property string appName: notif.notification?.appName ?? ""
        property string appIcon: notif.notification?.appIcon ?? ""
        property string image: notif.notification?.image ?? ""
        property int urgency: notif.notification?.urgency ?? NotificationUrgency.Normal
        property var actions: notif.notification?.actions ?? []

        // 既読かどうかは境界時刻との比較で決まる。個別のフラグは持たない。
        readonly property bool read: notif.timestamp.getTime() <= root.lastReadAt

        readonly property bool withinRetention: (root.now.getTime() - notif.timestamp.getTime()) < root.retentionHours * 3600000

        // 畳んでいる最中。表示側はこれを見て消える動きを再生する。
        property bool dismissing: false

        // カーソルが乗っている間は寿命を数えない。各モニタの表示が書き戻す集約点。
        property bool popupHovered: false

        // トーストを自動で消すまでの ms。0 は消さない。
        // freedesktop の expireTimeout は -1 が「送り手は決めない」、0 が「消さない」。
        // quickshell のドキュメントは秒単位を謳うが、実装は D-Bus の ms を無変換で
        // 保持している(notification.cpp: bExpireTimeout = expireTimeout)。ms のまま使う。
        readonly property int popupTimeout: {
            if (notif.urgency === NotificationUrgency.Critical)
                return 0;
            const requested = notif.notification?.expireTimeout ?? -1;
            return requested < 0 ? root.defaultPopupTimeout : requested;
        }

        readonly property Timer popupTimer: Timer {
            interval: notif.popupTimeout
            running: notif.popupTimeout > 0 && !notif.popupHovered && !notif.dismissing
            onTriggered: root.dismissPopup(notif)
        }

        // 送り手が D-Bus で閉じた通知(CloseNotification)。破棄される前に値を固定し、
        // トーストも畳む。
        readonly property Connections closeWatch: Connections {
            target: notif.notification
            function onClosed(): void {
                notif.freeze();
                root.dismissPopup(notif);
            }
        }

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

        // 表示用の値の束縛を切り、最後の値を履歴に固定する。
        // actions と image は元オブジェクトと一緒に死ぬ参照なので空にする。
        function freeze(): void {
            const source = notif.notification;
            if (!source)
                return;
            notif.summary = source.summary;
            notif.body = source.body;
            notif.appName = source.appName;
            notif.appIcon = source.appIcon;
            notif.image = "";
            notif.urgency = source.urgency;
            notif.actions = [];
        }

        // freedesktop の既定アクションは identifier "default"。無ければ先頭で代用する。
        // QML の list プロパティは Array のメソッドを持たないので、配列へ写してから探す。
        function invokeDefaultAction(): void {
            const list = [...notif.actions];
            (list.find(action => action.identifier === "default") ?? list[0])?.invoke();
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
