import QtQuick 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme" as QsTheme

// waybar 直下・右上に浮くカード型ウィンドウ。
// 配置・閉じる操作・出現アニメと、面（角丸/枠線/影）を 1 つに持つ。
// 利用側は width / padding と中身だけを与える。高さは中身から導出する。
PanelWindow {
    id: root

    property bool shouldShow: false
    required property int cardWidth
    property int padding: 16
    property real maxHeight: root.screen ? root.screen.height - 56 : 0

    property real shadowOpacity: 0.35
    property real shadowBlur: 1.0
    property real shadowOffsetY: 6

    default property alias content: contentItem.data

    // 開く瞬間のフォーカスモニタに固定（ライブバインディングだと表示中にフォーカス移動で窓が付いてくる）
    onShouldShowChanged: {
        if (shouldShow)
            screen = [...Quickshell.screens].find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
    }

    // バー下端より下だけを覆う透明オーバーレイ（枠外クリック検出・バーには被らない）
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    margins.top: QsTheme.Appearance.panel.barOffset
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: root.shouldShow || card.opacity > 0

    WlrLayershell.keyboardFocus: root.shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.shouldShow = false
        onVisibleChanged: if (visible)
            forceActiveFocus()

        // 枠外クリックで閉じる
        MouseArea {
            anchors.fill: parent
            onClicked: root.shouldShow = false
        }

        Rectangle {
            id: card

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: QsTheme.Appearance.margin.s
            anchors.rightMargin: QsTheme.Appearance.panel.edgeGap

            width: root.cardWidth
            height: Math.min(contentItem.implicitHeight + root.padding * 2, root.maxHeight)

            color: QsTheme.Theme.panel
            radius: QsTheme.Appearance.radius.m
            border.width: 1
            border.color: QsTheme.Theme.border
            clip: true

            scale: 0.94
            opacity: 0
            transformOrigin: Item.TopRight

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: QsTheme.Theme.shadow
                shadowOpacity: root.shadowOpacity
                shadowBlur: root.shadowBlur
                shadowVerticalOffset: root.shadowOffsetY
            }

            // カード上のクリックはバックドロップへ伝播させない
            MouseArea {
                anchors.fill: parent
            }

            Item {
                id: contentItem
                anchors.fill: parent
                anchors.margins: root.padding
            }

            states: State {
                name: "visible"
                when: root.shouldShow
                PropertyChanges {
                    target: card
                    opacity: 1
                    scale: 1.0
                }
            }

            transitions: [
                Transition {
                    to: "visible"
                    ParallelAnimation {
                        NumberAnimation {
                            property: "opacity"
                            duration: QsTheme.Appearance.anim.durations.normal
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            property: "scale"
                            duration: QsTheme.Appearance.anim.durations.medium
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.3
                        }
                    }
                },
                Transition {
                    from: "visible"
                    ParallelAnimation {
                        NumberAnimation {
                            property: "opacity"
                            duration: QsTheme.Appearance.anim.durations.fast
                            easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            property: "scale"
                            to: 0.94
                            duration: QsTheme.Appearance.anim.durations.fast
                        }
                    }
                }
            ]
        }
    }
}
