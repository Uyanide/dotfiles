import QtQuick
import Quickshell
pragma Singleton

Singleton {
    id: root

    function write(text) {
        Quickshell.execDetached(["sh", "-c", `echo ${text} | wl-copy -n`]);
    }

}
