import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property int cycleInterval: 900 // in seconds
    property var wallpapers: SettingsService.cycleWallpapers

    function applyNext() {
        if (root.wallpapers.length === 0) {
            Logger.w("WallpaperCycle", "No wallpapers to cycle through, skipping.");
            return ;
        }
        cycleTimer.stop();
        const current = SettingsService.backgroundPath;
        let index = -1;
        if (current) {
            for (let i = 0; i < root.wallpapers.length; i++) {
                if (root.wallpapers[i] === current) {
                    index = i;
                    break;
                }
            }
        }
        if (index === -1) {
            Logger.w("WallpaperCycle", "Current wallpaper not found in cycle list, starting from the beginning.");
            index = 0;
        } else {
            index = (index + 1) % root.wallpapers.length;
        }
        const nextWallpaper = root.wallpapers[index];
        Logger.i("WallpaperCycle", "Cycling to next wallpaper: " + nextWallpaper);
        _apply(nextWallpaper);
        cycleTimer.start();
    }

    function _apply(path) {
        Quickshell.execDetached(["sh", "-c", "wallreel -a '" + path + "'"]);
    }

    Timer {
        id: cycleTimer

        running: false
        repeat: true
        interval: root.cycleInterval * 1000
        onTriggered: {
            root.applyNext();
        }
    }

}
