import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    function show(title, message, icon = "", urgency = "normal", timeout = 5000) {
        if (icon)
            action.command = ["notify-send", "-u", urgency, "-i", icon, "-t", timeout.toString(), title, message];
        else
            action.command = ["notify-send", "-u", urgency, "-t", timeout.toString(), title, message];
        action.startDetached();
    }

    Process {
        id: action

        running: false
    }

}
