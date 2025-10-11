import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    function write(text) {
        action.command = ["sh", "-c", `echo ${text} | wl-copy -n`];
        action.startDetached();
    }

    Process {
        id: action

        running: false
    }

}
