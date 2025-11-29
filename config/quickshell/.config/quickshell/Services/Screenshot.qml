import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    function onScreenshotCaptured(path) {
        if (!path || typeof path !== "string")
            return ;

        Quickshell.execDetached(["~/.local/scripts/screenshot-script", "edit", path]);
    }

}
