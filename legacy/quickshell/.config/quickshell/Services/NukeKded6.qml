import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    property bool done: false

    Process {
        id: process

        running: true
        command: ["sh", "-c", "pgrep -x kded6 && { { type kquitapp6 && kquitapp6 kded6 || pkill -9 -x kded6; }; sleep 0.5; }"]
        onExited: (code, status) => {
            done = true;
        }
    }

}
