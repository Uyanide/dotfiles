import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
pragma Singleton

Singleton {
    id: root

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell/"
    // also create recording directory here
    readonly property string recordingDir: Quickshell.env("HOME") + "/Videos/recordings/"
    readonly property var cacheFiles: Object.freeze(["Location.json", "Ip.json", "Notifications.json", "LyricsOffset.txt", "Network.json"])
    property bool loaded: false
    readonly property string locationCacheFile: cacheDir + "Location.json"
    readonly property string ipCacheFile: cacheDir + "Ip.json"
    readonly property string notificationsCacheFile: cacheDir + "Notifications.json"
    readonly property string lyricsOffsetCacheFile: cacheDir + "LyricsOffset.txt"
    readonly property string networkCacheFile: cacheDir + "Network.json"

    Process {
        id: process

        running: true
        command: ["sh", "-c", `mkdir -p ${cacheDir} && mkdir -p ${recordingDir} && touch ${cacheDir + cacheFiles.join(` && touch ${cacheDir}`)}`]
        onExited: (code, status) => {
            if (code === 0)
                loaded = true;
            else
                Logger.error("CacheService", `Failed to create cache files: ${command.join(" ")}`);
        }
    }

}
