pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../../utils" as QsUtils

Singleton {
    id: root
    
    property bool inhibited: false
    property int inhibitorPid: -1
    
    onInhibitedChanged: {
        QsUtils.Logger.debug("IdleInhibitor", `Inhibited changed: ${inhibited}`)
        if (inhibited) {
            enableInhibitor()
        } else {
            disableInhibitor()
        }
    }
    
    function enableInhibitor() {
        QsUtils.Logger.info("IdleInhibitor", "Enabling")
        enableProcess.running = true
    }
    
    function disableInhibitor() {
        QsUtils.Logger.info("IdleInhibitor", "Disabling")
        disableProcess.running = true
    }
    
    // Enable idle inhibitor using systemd-inhibit
    Process {
        id: enableProcess
        command: ["/bin/sh", "-c", "systemd-inhibit --what=idle --who=QuickShell --why='Caffeine mode enabled' sleep infinity & echo $!"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const pid = parseInt(data.trim())
                if (!isNaN(pid) && pid > 0) {
                    root.inhibitorPid = pid
                    QsUtils.Logger.debug("IdleInhibitor", `Started PID=${pid}`)
                }
            }
        }
    }
    
    // Disable idle inhibitor
    Process {
        id: disableProcess
        command: ["/bin/sh", "-c", root.inhibitorPid > 0 ? 
                  `kill ${root.inhibitorPid} 2>/dev/null || pkill -f 'systemd-inhibit.*QuickShell'` :
                  "pkill -f 'systemd-inhibit.*QuickShell'"]
        running: false
        
        onExited: {
            root.inhibitorPid = -1
            QsUtils.Logger.debug("IdleInhibitor", "Stopped")
        }
    }
    
    Component.onCompleted: {
        QsUtils.Logger.debug("IdleInhibitor", "Service loaded")
    }
}
