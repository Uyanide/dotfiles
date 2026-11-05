import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property int cycleInterval: SettingsService.cycleInterval
    property list<string> wallpapers: []
    property bool enabled: SettingsService.cycleEnabled
    property bool shuffle: SettingsService.cycleShuffle
    property int timeUntilNextCycle: SettingsService.cycleInterval
    property double nextCycleDeadlineMs: 0
    property int _startIndex: 0

    Connections {
        target: SettingsService

        function onCycleWallpapersChanged() {
            _initPaths();
            _initTimer();
        }

        function onCycleEnabledChanged() {
            _initTimer();
        }

        function onCycleShuffleChanged() {
            _initPaths();
            _initTimer();
        }

        function onCycleIntervalChanged() {
            if (enabled && cycleTimer.running) {
                _scheduleCycle(root.cycleInterval);
            }
        }
    }

    Component.onCompleted: {
        _initPaths();
        _initTimer();
    }

    function _initPaths() {
        if (!shuffle) {
            wallpapers = SettingsService.cycleWallpapers;
        } else {
            wallpapers = _shuffle(SettingsService.cycleWallpapers);
        }
        Logger.d("WallpaperCycle", "Initialized wallpapers: " + wallpapers.length + " paths" + (shuffle ? " (shuffled)" : ""));
    }

    function _initTimer() {
        if (enabled && root.wallpapers.length > 0) {
            const remainingSeconds = Math.max(1, nextCycleDeadlineMs > 0
                ? _secondsUntilDeadline()
                : root.timeUntilNextCycle);
            _scheduleCycle(remainingSeconds);
        } else {
            if (cycleTimer.running && nextCycleDeadlineMs > 0) {
                timeUntilNextCycle = _secondsUntilDeadline();
            }
            cycleTimer.stop();
            nextCycleDeadlineMs = 0;
        }
    }

    function _scheduleCycle(secondsFromNow) {
        if (!enabled) return;
        const seconds = Math.max(1, Math.floor(secondsFromNow));
        timeUntilNextCycle = seconds;
        nextCycleDeadlineMs = Date.now() + (seconds * 1000);
        cycleTimer.interval = seconds * 1000;
        cycleTimer.stop();
        cycleTimer.start();
        Logger.d("WallpaperCycle", "Scheduled next cycle in " + seconds + " seconds.");
    }

    function _secondsUntilDeadline() {
        return Math.max(0, Math.ceil((nextCycleDeadlineMs - Date.now()) / 1000));
    }

    function _shuffle(paths) {
        const shuffled = paths.slice();
        for (let i = shuffled.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
        }
        return shuffled;
    }

    function playPause() {
        SettingsService.cycleEnabled = !SettingsService.cycleEnabled;
    }

    function toggleShuffle() {
        SettingsService.cycleShuffle = !SettingsService.cycleShuffle;
    }

    function applyPrev(resetCountdown) {
        if (resetCountdown === undefined)
            resetCountdown = true;

        if (root.wallpapers.length === 0) {
            Logger.w("WallpaperCycle", "No wallpapers to cycle through, skipping.");
            return false;
        }
        cycleTimer.stop();
        let index = _findIndex(SettingsService.backgroundPath);
        if (index === -1) {
            Logger.w("WallpaperCycle", "Current wallpaper not found in cycle list, starting from the end.");
            index = root.wallpapers.length - 1;
        } else {
            index = (index - 1 + root.wallpapers.length) % root.wallpapers.length;
        }
        const prevWallpaper = root.wallpapers[index];
        Logger.i("WallpaperCycle", "Cycling to previous wallpaper: " + prevWallpaper);
        _apply(prevWallpaper);
        if (enabled && resetCountdown) {
            _scheduleCycle(root.cycleInterval);
        }
        return true;
    }

    function applyNext(resetCountdown) {
        if (resetCountdown === undefined)
            resetCountdown = true;

        if (root.wallpapers.length === 0) {
            Logger.w("WallpaperCycle", "No wallpapers to cycle through, skipping.");
            return false;
        }
        cycleTimer.stop();
        let index = _findIndex(SettingsService.backgroundPath);
        if (index === -1) {
            Logger.w("WallpaperCycle", "Current wallpaper not found in cycle list, starting from the beginning.");
            index = 0;
        } else {
            index = (index + 1) % root.wallpapers.length;
        }
        const nextWallpaper = root.wallpapers[index];
        Logger.i("WallpaperCycle", "Cycling to next wallpaper: " + nextWallpaper);
        _apply(nextWallpaper);
        if (enabled && resetCountdown) {
            _scheduleCycle(root.cycleInterval);
        }
        return true;
    }

    function _apply(path) {
        Logger.d("WallpaperCycle", "Applying wallpaper: " + path);
        Quickshell.execDetached(["wallreel", "-a", path]);
    }

    function _findIndex(path) {
        for (let i = 0; i < root.wallpapers.length; i++) {
            if (root.wallpapers[i] === path)
                return i;
        }
        return -1;
    }

    Timer {
        id: cycleTimer

        running: false
        repeat: false
        onTriggered: {
            const applied = root.applyNext(false);
            if (applied && root.enabled) {
                _scheduleCycle(root.cycleInterval);
            }
        }
    }

    Timer {
        id: updateTimeTimer

        running: cycleTimer.running
        repeat: true
        interval: 1000
        onTriggered: {
            if (nextCycleDeadlineMs > 0) {
                timeUntilNextCycle = _secondsUntilDeadline();
            }
        }
    }

}
