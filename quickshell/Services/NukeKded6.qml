import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
pragma Singleton

Singleton {
    property bool done: false

    Process {
        id: process

        running: true
        command: ["sh", "-c", "kquitapp6 kded6"]
        onExited: (code, status) => {
            if (code !== 0)
                Logger.warn("NukeKded6", `Failed to kill kded6: ${code}`);

            done = true;
        }
    }

}
