import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    id: root

    readonly property string backgroundWidth: "2560"
    readonly property string backgroundHeight: "1440"
    property string cachedPath: ""
    property string previewPath: ""
    // Preserved for getBlurredOverview
    readonly property string tintColor: Colors.mSurface
    readonly property real tintOpacity: 0.5
    readonly property real blurPercentage: 1
    readonly property real blurRadius: 32

    function loadBackground() {
        if (!SettingsService.backgroundPath) {
            Logger.w("BackgroundService", "No background path set, skipping loading background.");
            return ;
        }
        ImageCacheService.getLarge(SettingsService.backgroundPath, backgroundWidth, backgroundHeight, function(path) {
            if (!path) {
                Logger.e("BackgroundService", "Failed to load background image from path: " + SettingsService.backgroundPath);
                return ;
            }
            cachedPath = path;
            Logger.i("BackgroundService", "Loaded background image as cached path: " + path);
        });
    }

    function previewWallpaper(path) {
        if (!path) {
            previewPath = "";
            return ;
        }
        ImageCacheService.checkFileExists(path, function(exists) {
            if (!exists) {
                previewPath = "";
                return ;
            }
            previewPath = path;
        });
    }

    function setWallpaper(path) {
        if (!path)
            return ;

        previewPath = ""; // clear preview path
        ImageCacheService.checkFileExists(path, function(exists) {
            if (!exists)
                return ;

            SettingsService.backgroundPath = path;
            loadWallpaperDebouncer.start();
        });
    }

    function toggleChooser() {
        if (wallreelProcess.running)
            wallreelProcess.signal(2);
        else
            wallreelProcess.running = true;
    }

    Component.onCompleted: {
        loadWallpaperDebouncer.start();
    }

    Connections {
        function onBackgroundPathChanged() {
            loadWallpaperDebouncer.start();
        }

        target: SettingsService
    }

    Timer {
        id: loadWallpaperDebouncer

        interval: 200
        running: false
        repeat: false
        onTriggered: {
            root.loadBackground();
        }
    }

    Process {
        id: wallreelProcess

        running: false
        command: ["wallreel"]
    }

}
