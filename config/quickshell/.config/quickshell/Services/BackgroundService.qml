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
    property string displayPath: ""
    property bool inPreviewMode: false
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
                cachedPath = "";
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
        cachedPath = ""; // clear cached path
        ImageCacheService.checkFileExists(path, function(exists) {
            if (!exists)
                return ;

            SettingsService.backgroundPath = path;
            loadTimer.restart();
        });
    }

    function openChooser() {
        if (!wallreelProcess.running)
            wallreelProcess.running = true;

    }

    function updateDisplay() {
        if (root.previewPath) {
            root.displayPath = root.previewPath;
            root.inPreviewMode = true;
        } else if (root.cachedPath) {
            root.displayPath = root.cachedPath;
            root.inPreviewMode = false;
        } else {
            root.displayPath = "";
            root.inPreviewMode = false;
        }
    }

    onCachedPathChanged: {
        Qt.callLater(updateDisplay);
    }
    onPreviewPathChanged: {
        Qt.callLater(updateDisplay);
    }
    Component.onCompleted: {
        loadTimer.start();
    }

    Timer {
        id: loadTimer

        interval: 300
        running: false
        repeat: false
        onTriggered: {
            loadBackground();
        }
    }

    Timer {
        id: setDisplayTimer

        interval: 100
        running: false
        repeat: false
        onTriggered: {
        }
    }

    Process {
        id: wallreelProcess

        running: false
        command: ["wallreel"]
    }

}
