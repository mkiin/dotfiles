import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme" as QsTheme

PanelWindow {
    id: root

    property bool shouldShow: false
    required property int panelWidth
    default property alias content: slot.data

    // 開く瞬間のフォーカスモニタに固定（ライブバインディングだと表示中にフォーカス移動で窓が付いてきてしまう）
    onShouldShowChanged: {
        if (shouldShow)
            screen = [...Quickshell.screens].find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    }

    // バー下端より下だけを覆う透明オーバーレイ（枠外クリック検出・バーには被らない）
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    margins {
        top: QsTheme.Appearance.panel.barOffset
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shouldShow || card.opacity > 0

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.shouldShow = false
        onVisibleChanged: if (visible) forceActiveFocus()

        // 枠外クリックで閉じる
        MouseArea {
            anchors.fill: parent
            onClicked: root.shouldShow = false
        }

        Item {
            id: card
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: QsTheme.Appearance.margin.s
            anchors.rightMargin: QsTheme.Appearance.panel.edgeGap
            width: root.panelWidth
            height: slot.children.length > 0 ? slot.children[0].implicitHeight : 0

            scale: 0.94
            opacity: 0
            transformOrigin: Item.TopRight

            // カード上のクリックはバックドロップへ伝播させない
            MouseArea { anchors.fill: parent }

            Item {
                id: slot
                anchors.fill: parent
            }

            states: State {
                name: "visible"
                when: root.shouldShow
                PropertyChanges { target: card; opacity: 1; scale: 1.0 }
            }

            transitions: [
                Transition {
                    to: "visible"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: QsTheme.Appearance.anim.durations.normal; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; duration: QsTheme.Appearance.anim.durations.medium; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                    }
                },
                Transition {
                    from: "visible"
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; duration: QsTheme.Appearance.anim.durations.fast; easing.type: Easing.InQuad }
                        NumberAnimation { property: "scale"; to: 0.94; duration: QsTheme.Appearance.anim.durations.fast }
                    }
                }
            ]
        }
    }
}
