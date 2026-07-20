import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".." as QsRoot
import "../theme" as QsTheme

// waybar 直下・右上に浮くカード型ウィンドウ。
// 配置・閉じる操作と、面（角丸/枠線/影）を持つ。
// 利用側は cardWidth / padding と中身だけを与える。高さは中身から導出する。
PanelWindow {
    id: root

    property bool shouldShow: false
    required property int cardWidth
    property int padding: QsTheme.Appearance.padding.l
    property real maxHeight: root.screen ? root.screen.height - QsRoot.Config.barHeight * 2 : 0

    property real shadowOpacity: 0.35
    property real shadowBlur: 1.0
    property real shadowOffsetY: 6

    default property alias content: contentItem.data

    // 開く瞬間のフォーカスモニタに固定（ライブバインディングだと表示中にフォーカス移動で窓が付いてくる）
    onShouldShowChanged: {
        if (shouldShow)
            screen = [...Quickshell.screens].find(monitor => monitor.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
    }

    // バー下端より下だけを覆う透明オーバーレイ（枠外クリック検出・バーには被らない）
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    margins.top: QsRoot.Config.barHeight
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: root.shouldShow

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
            anchors.topMargin: QsTheme.Appearance.edgeGap
            anchors.rightMargin: QsTheme.Appearance.edgeGap

            width: root.cardWidth
            height: Math.min(contentItem.implicitHeight + root.padding * 2, root.maxHeight)

            color: QsTheme.Theme.panel
            radius: QsTheme.Appearance.radius.m
            border.width: 1
            border.color: QsTheme.Theme.border
            clip: true

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

            // 幅は親から、高さは子から決まる。中身は Layout の子として並ぶ。
            ColumnLayout {
                id: contentItem

                x: root.padding
                y: root.padding
                width: card.width - root.padding * 2
                spacing: QsTheme.Appearance.spacing.m
            }
        }
    }
}
