import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import ".." as QsRoot
import "../ui" as QsUi
import "../theme" as QsTheme
import "../features/notifications" as QsNotifications

// waybar 直下・右上に積む通知トースト。全モニタへ同じものを出す。
// PopupCard は使わない。あれは画面全面を覆って枠外クリックを拾う器で、
// 常時出るトーストに使うと下のウィンドウの操作を奪う。
// フォーカスモニタだけに出す案は捨てた。通知は視線がどこにあっても気づけるべきで、
// 到着時にフォーカスしていたモニタへ固定すると見落とす。
Variants {
    id: variants

    readonly property var notifs: QsNotifications.Notifs
    readonly property int popupCount: variants.notifs.popups.length

    model: Quickshell.screens

    PanelWindow {
        id: root

        required property var modelData

        // mask のスロットへ流し込むカード。Region.regions は静的リストで動的に増やせないため、
        // delegate 側から登録してもらう。並び順は和を取るだけなので問わない。
        property var cards: []

        screen: root.modelData
        visible: variants.popupCount > 0

        // 影は MultiEffect が面の外側へ描くので、窓を影のぶん広げないとレイヤーシェル面の端で
        // 切り落とされる。広げるのは左と下、それに画面端までの右の隙間ぶん。上はバーに接していて
        // 広げるとバーへ影が滲むため、offsetY のぶん元々薄い上側は諦める。
        readonly property int shadowRoom: QsTheme.Appearance.shadow.margin

        anchors.top: true
        anchors.right: true
        margins.top: QsRoot.Config.barHeight
        margins.right: 0

        implicitWidth: QsTheme.Appearance.popup.toastWidth + root.shadowRoom + QsTheme.Appearance.edgeGap
        // 0 高の窓は作れないので下限を 1px 置く。入力は mask で切ってあるので実害はない。
        implicitHeight: Math.max(1, column.implicitHeight + root.shadowRoom)

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        // カードの矩形の和だけを入力領域にする。これが無いと窓の透明部分が下のウィンドウの
        // クリックを吸う。Column を丸ごと渡すとカード間の隙間と影の余白まで吸ってしまうので、
        // カード 1 枚ずつを積む。スロット数は Notifs.maxPopups と揃える。
        // 空きスロットは item が null になり、空領域として和に寄与しない。
        mask: Region {
            Region {
                item: root.cards[0] ?? null
            }

            Region {
                item: root.cards[1] ?? null
            }

            Region {
                item: root.cards[2] ?? null
            }
        }

        Column {
            id: column

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.rightMargin: QsTheme.Appearance.edgeGap

            width: QsTheme.Appearance.popup.toastWidth
            spacing: QsTheme.Appearance.spacing.s

            Repeater {
                // JS 配列を直接渡すと再代入のたびに全 delegate が作り直される。
                // ScriptModel はオブジェクトの同一性で差分を取り、既存の delegate を保つ。
                model: ScriptModel {
                    values: variants.notifs.popups
                }

                delegate: Rectangle {
                    id: toast

                    required property var modelData

                    readonly property int contentHeight: content.implicitHeight + QsTheme.Appearance.padding.m * 2
                    readonly property color accent: toast.modelData.urgency === NotificationUrgency.Critical ? QsTheme.Theme.error : QsTheme.Theme.primary
                    readonly property int accentWidth: 3

                    width: column.width

                    // 高さは動かさない。カード高を毎フレーム変えると Column → PanelWindow と
                    // 伝播して窓のリサイズと入力マスクの更新が毎フレーム走り、影の再合成も
                    // 重なって目に見えて引っかかる。繰り上がりは配列から抜けた 1 フレームで済ませる。
                    height: toast.contentHeight

                    // hyprland の quickshell-glass-blur layerrule とセットでガラスになる
                    color: QsTheme.Theme.glassTint
                    radius: QsTheme.Appearance.radius.s
                    border.width: 1
                    border.color: QsTheme.Theme.glassBorder
                    clip: true

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: QsTheme.Theme.shadow
                        shadowOpacity: QsTheme.Appearance.shadow.opacity
                        shadowBlur: QsTheme.Appearance.shadow.blur
                        shadowVerticalOffset: QsTheme.Appearance.shadow.offsetY
                    }

                    // delegate は通知 1 件 × モニタ 1 面につき 1 度しか作られないので、
                    // 出現アニメに再生済みガードは要らない。畳みかけの通知を途中から
                    // 引き継ぐのは、表示中にモニタが増えた場合だけ。
                    Component.onCompleted: {
                        root.cards = [...root.cards, toast];
                        if (toast.modelData.dismissing)
                            exitAnim.start();
                        else
                            appearAnim.start();
                    }

                    Component.onDestruction: root.cards = root.cards.filter(card => card !== toast)

                    // 出現は拡大だけで表す。窓の右端が画面端に接しているため、窓の外から
                    // 滑り込ませることはできない。不透明度は消える動きに使うので触らない。
                    QsUi.Anim {
                        id: appearAnim

                        target: toast
                        property: "scale"
                        from: 0.96
                        to: 1
                    }

                    // 消える動きは表示側が再生し、終えてから配列を抜く。モデルは dismissing で
                    // 消え始めを告げるだけで、動きの長さを知らない。
                    // 全モニタが同時に完了を報告しても removePopup は冪等。
                    QsUi.Anim {
                        id: exitAnim

                        target: toast
                        property: "opacity"
                        to: 0
                        speed: "fast"
                        onFinished: variants.notifs.removePopup(toast.modelData)
                    }

                    Connections {
                        target: toast.modelData
                        function onDismissingChanged(): void {
                            if (toast.modelData.dismissing)
                                exitAnim.start();
                        }
                    }

                    HoverHandler {
                        id: hover
                    }

                    // 寿命を数えるのは通知自身。ここは乗っているかどうかを書き戻すだけ。
                    Binding {
                        target: toast.modelData
                        property: "popupHovered"
                        value: hover.hovered
                    }

                    // 本文のクリックで通知の既定アクションを実行する。閉じるボタンは後で宣言され
                    // 上に重なるので入力は奪わない。
                    QsUi.StateLayer {
                        color: QsTheme.Theme.text
                        onClicked: {
                            toast.modelData.invokeDefaultAction();
                            variants.notifs.dismissPopup(toast.modelData);
                        }
                    }

                    // 角丸の縁に直線を突き当てると角が削れて見えるため、内側に浮かせた丸端の棒にする。
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: QsTheme.Appearance.padding.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: toast.accentWidth
                        height: Math.max(0, toast.height - QsTheme.Appearance.padding.m * 2)
                        radius: width / 2
                        color: toast.accent
                        visible: toast.modelData.urgency !== NotificationUrgency.Low
                    }

                    RowLayout {
                        id: content

                        x: QsTheme.Appearance.padding.s * 2 + toast.accentWidth
                        y: QsTheme.Appearance.padding.m
                        width: toast.width - x - QsTheme.Appearance.padding.m
                        spacing: QsTheme.Appearance.spacing.s

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: toast.modelData.summary || "Notification"
                                font.family: QsTheme.Appearance.fontFamily
                                font.pixelSize: QsTheme.Appearance.fontSize.s
                                font.weight: Font.DemiBold
                                color: QsTheme.Theme.text
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: toast.modelData.body
                                font.family: QsTheme.Appearance.fontFamily
                                font.pixelSize: QsTheme.Appearance.fontSize.xs
                                color: QsTheme.Theme.textVariant
                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                visible: text !== ""
                            }
                        }

                        QsUi.Button {
                            Layout.alignment: Qt.AlignTop
                            variant: "ghost"
                            size: "sm"
                            iconOnly: true
                            text: "󰅖"
                            onClicked: variants.notifs.dismissPopup(toast.modelData)
                        }
                    }
                }
            }
        }
    }
}
