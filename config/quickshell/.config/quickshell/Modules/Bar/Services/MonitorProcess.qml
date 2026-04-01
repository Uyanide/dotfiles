import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    function toggle() {
        if (process.running) {
            process.signal(15);
            return ;
        }
        process.running = true;
    }

    Process {
        id: process

        running: false
        command: ["ghostty", "+new-window", "-e", "btop"]
    }

}
