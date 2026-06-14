import Quickshell
import Quickshell.Io
import QtQuick
import "modules/bar/components" as Bt
import "services" as QsServices

ShellRoot {
    Bt.BluetoothPopupWindow {
        id: btPopup
        shouldShow: true
        onShouldShowChanged: if (!shouldShow) quitTimer.start()
    }

    // 壁紙変更後に matugen post_hook から呼ぶカラーリロード (開いたまま反映)
    IpcHandler {
        target: "theme"
        function reload(): void { QsServices.Pywal.reload() }
    }

    // launch-on-click: end the process once the popup has animated out
    Timer {
        id: quitTimer
        interval: 220
        onTriggered: Qt.quit()
    }
}
