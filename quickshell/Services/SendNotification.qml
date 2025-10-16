import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    function show(title, message, icon = "", urgency = "normal") {
        if (icon)
            Quickshell.execDetached(["notify-send", "-u", urgency, "-i", icon, title, message, "-a", "quickshell"]);
        else
            Quickshell.execDetached(["notify-send", "-u", urgency, title, message, "-a", "quickshell"]);
    }

}
