import QtQuick
import Quickshell
pragma Singleton

Singleton {
    id: root

    readonly property string cacheDir: Quickshell.shellDir + "/Assets/Cache/"
    readonly property string configDir: Quickshell.shellDir + "/Assets/Config/"
    readonly property string recordingDir: Quickshell.env("HOME") + "/Videos/recordings/"
}
