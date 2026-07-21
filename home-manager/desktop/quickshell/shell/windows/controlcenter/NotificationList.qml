import QtQuick 6.10
import QtQuick.Controls 6.10
import QtQuick.Layouts 6.10
import "../../ui" as QsUi
import "../../theme" as QsTheme
import "../../features/notifications" as QsNotifications

// 通知履歴。パネルより一段沈んだ面に、ヘッダーとスクロールするリストを積む。
Rectangle {
    id: root

    readonly property var notifs: QsNotifications.Notifs

    implicitHeight: column.implicitHeight + QsTheme.Appearance.padding.m * 2

    color: QsTheme.Theme.inset
    radius: QsTheme.Appearance.radius.m
    border.width: 1
    border.color: QsTheme.Theme.border

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: QsTheme.Appearance.padding.m
        spacing: QsTheme.Appearance.spacing.s

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Notifications"
                font.family: QsTheme.Appearance.fontFamily
                font.pixelSize: QsTheme.Appearance.fontSize.m
                font.weight: Font.DemiBold
                color: QsTheme.Theme.text
            }

            Item {
                Layout.fillWidth: true
            }

            QsUi.Button {
                variant: "ghost"
                size: "sm"
                text: "Clear All"
                visible: root.notifs.recentNotifications.length > 0
                onClicked: root.notifs.clearAll()
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: root.notifs.recentNotifications.length > 0 ? Math.min(list.contentHeight, QsTheme.Appearance.popup.notificationMaxHeight) : empty.implicitHeight
            Layout.minimumHeight: QsTheme.Appearance.popup.notificationMinHeight
            clip: true
            spacing: QsTheme.Appearance.spacing.s

            model: root.notifs.recentNotifications

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 4
            }

            add: Transition {
                QsUi.Anim {
                    property: "opacity"
                    from: 0
                    to: 1
                }
            }

            remove: Transition {
                QsUi.Anim {
                    property: "opacity"
                    to: 0
                    speed: "fast"
                }
            }

            QsUi.Empty {
                id: empty

                anchors.centerIn: parent
                width: parent.width
                variant: "icon"
                icon: "󰂚"
                title: "No Notifications"
                visible: root.notifs.recentNotifications.length === 0
            }

            delegate: Rectangle {
                id: row

                required property var modelData

                width: list.width
                height: content.implicitHeight + QsTheme.Appearance.padding.s * 2
                radius: QsTheme.Appearance.radius.s
                color: QsTheme.Theme.card

                // 行のクリック。中身より下に敷き、閉じるボタンの入力を奪わない。
                QsUi.StateLayer {
                    z: -1
                    color: QsTheme.Theme.text
                    onClicked: {
                        if (row.modelData.actions.length > 0)
                            row.modelData.actions[0].invoke();
                    }
                }

                RowLayout {
                    id: content

                    anchors.fill: parent
                    anchors.margins: QsTheme.Appearance.padding.s
                    spacing: QsTheme.Appearance.spacing.m

                    Item {
                        Layout.preferredWidth: QsTheme.Appearance.size.headerIcon
                        Layout.preferredHeight: QsTheme.Appearance.size.headerIcon
                        Layout.alignment: Qt.AlignTop

                        Rectangle {
                            anchors.fill: parent
                            radius: QsTheme.Appearance.radius.s
                            color: QsTheme.Theme.primary
                            opacity: 0.15
                        }

                        Image {
                            id: appIcon

                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: row.modelData.appIcon ? (row.modelData.appIcon.startsWith("/") ? "file://" + row.modelData.appIcon : "image://icon/" + row.modelData.appIcon) : ""
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰂚"
                            font.family: QsTheme.Appearance.iconFamily
                            font.pixelSize: QsTheme.Appearance.fontSize.l
                            color: QsTheme.Theme.primary
                            visible: !appIcon.visible
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.summary || "Notification"
                            font.family: QsTheme.Appearance.fontFamily
                            font.pixelSize: QsTheme.Appearance.fontSize.s
                            font.weight: Font.DemiBold
                            color: QsTheme.Theme.text
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.body
                            font.family: QsTheme.Appearance.fontFamily
                            font.pixelSize: QsTheme.Appearance.fontSize.xs
                            color: QsTheme.Theme.textVariant
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            visible: text !== ""
                        }

                        Text {
                            Layout.fillWidth: true
                            text: [row.modelData.appName, row.modelData.timeString].filter(part => part !== "").join(" · ")
                            font.family: QsTheme.Appearance.fontFamily
                            font.pixelSize: QsTheme.Appearance.fontSize.xs
                            color: QsTheme.Theme.textVariant
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }

                    QsUi.Button {
                        Layout.alignment: Qt.AlignTop
                        variant: "ghost"
                        size: "sm"
                        iconOnly: true
                        text: "󰅖"
                        onClicked: root.notifs.remove(row.modelData)
                    }
                }
            }
        }
    }
}
