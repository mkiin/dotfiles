import Quickshell
import QtQuick
import "modules/bar/components" as Au

ShellRoot {
    Au.AudioPopupWindow {
        id: audioPopup
        shouldShow: true
        onShouldShowChanged: if (!shouldShow) quitTimer.start()
    }

    // launch-on-click: end the process once the popup has animated out
    Timer {
        id: quitTimer
        interval: 220
        onTriggered: Qt.quit()
    }
}
