import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell/"
    property var cacheFiles: ["Location.json", "Ip.json", "Notifications.json", "LyricsOffset.txt"]
    property bool loaded: false
    property string locationCacheFile: cacheDir + "Location.json"
    property string ipCacheFile: cacheDir + "Ip.json"
    property string notificationsCacheFile: cacheDir + "Notifications.json"
    property string lyricsOffsetCacheFile: cacheDir + "LyricsOffset.txt"

    Process {
        id: process

        running: true
        command: ["sh", "-c", `mkdir -p ${cacheDir} && touch ${cacheDir + cacheFiles.join(` && touch ${cacheDir}`)}`]
        onExited: (code, status) => {
            if (code === 0)
                root.loaded = true;
            else
                Logger.error("CacheService", `Failed to create cache files: ${command.join(" ")}`);
        }
    }

}
