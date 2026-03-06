import QtQuick
import Quickshell
import qs.Constants
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property string backgroundWidth: "2560"
    property string backgroundHeight: "1440"
    property string cachedPath: ""
    property string cachedBlurredPath: ""
    property string previewPath: ""
    // Preserved for getBlurredOverview
    property string tintColor: Colors.mSurface
    property bool isDarkMode: false

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
            ImageCacheService.getBlurredOverview(SettingsService.backgroundPath, backgroundWidth, backgroundHeight, tintColor, isDarkMode, function(blurredPath) {
                if (!blurredPath) {
                    Logger.e("BackgroundService", "Failed to load blurred background image from path: " + SettingsService.backgroundPath);
                    return ;
                }
                cachedBlurredPath = blurredPath;
                Logger.i("BackgroundService", "Loaded blurred background image as cached blurred path: " + blurredPath);
            });
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

}
