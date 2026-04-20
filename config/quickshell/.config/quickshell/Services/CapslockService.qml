import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property bool isCapslockOn: false

    onIsCapslockOnChanged: {
        TempNotificationService.showWithIcon("letter-case", root.isCapslockOn ? "CAPS LOCK ON" : "caps lock off");
    }

    Process {
        id: capslockMonitorProcess

        running: true
        command: ["led-monitor", "-l", "capslock"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (line.trim() === "1")
                    root.isCapslockOn = true;
                else if (line.trim() === "0")
                    root.isCapslockOn = false;
            }
        }

    }

}
