import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    function show(title, message, timeout = 5000, icon = "", urgency = "normal") {
        if (icon)
            Quickshell.execDetached(["notify-send", "-u", urgency, "-i", icon, "-t", timeout.toString(), title, message, "-a", "quickshell"]);
        else
            Quickshell.execDetached(["notify-send", "-u", urgency, "-t", timeout.toString(), title, message, "-a", "quickshell"]);
    }

}
