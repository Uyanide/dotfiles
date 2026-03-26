import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    function show(title, message, nohistory = false, icon = "", urgency = "normal") {
        const cmds = ["notify-send", "-u", urgency, "-a", "quickshell"];
        if (icon)
            cmds.push("-i", icon);

        if (nohistory) {
            cmds.push("--hint", "int:transient:1");
            cmds.push("--expire-time", "3000");
        }
        cmds.push(title, message);
        Quickshell.execDetached(cmds);
    }

}
