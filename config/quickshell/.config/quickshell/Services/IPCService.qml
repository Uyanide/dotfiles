import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services

Item {
    IpcHandler {
        function startOrStop() {
            RecordService.startOrStop();
        }

        function saveReplay() {
            RecordService.stopReplay();
        }

        target: "recording"
    }

    IpcHandler {
        function clearAll() {
            ImageCacheService.clearAll();
        }

        target: "cache"
    }

    IpcHandler {
        function preview(path: string) {
            BackgroundService.previewWallpaper(path);
        }

        function set(path: string) {
            BackgroundService.setWallpaper(path);
        }

        function next() {
            WallpaperCycle.applyNext();
        }

        function prev() {
            WallpaperCycle.applyPrev();
        }

        target: "background"
    }

    IpcHandler {
        function playPause() {
            MediaService.playPause();
        }

        function next() {
            MediaService.next();
        }

        function previous() {
            MediaService.previous();
        }

        function volumeUp() {
            AudioService.increaseVolume();
        }

        function volumeDown() {
            AudioService.decreaseVolume();
        }

        function toggleOutputMute() {
            AudioService.setOutputMuted(!AudioService.muted);
        }

        function toggleInputMute() {
            AudioService.setInputMuted(!AudioService.inputMuted);
        }

        target: "media"
    }

    IpcHandler {
        function set(name: string, value: color) {
            Colors.setColor(name, value);
        }

        function unset(name: string) {
            Colors.unsetColor(name);
        }

        function get(name: string) : string {
            const hex = String(Colors[name]);
            if (hex.startsWith("#") && hex.length === 9)
                return "#" + hex.substring(3);

            return hex;
        }

        target: "colors"
    }

    IpcHandler {
        function toggleLeft() {
            BarService.toggleLeft();
        }

        function toggleRight() {
            BarService.toggleRight();
        }

        function toggleLyrics() {
            LyricsService.toggleLyricsBar();
        }

        target: "bars"
    }

    IpcHandler {
        function toggle() {
            Caffeine.manualToggle();
        }

        target: "idleInhibitor"
    }

    IpcHandler {
        function toggle() {
            SunsetService.toggleSunset();
        }

        target: "sunset"
    }

    IpcHandler {
        function up() {
            BrightnessService.getMonitorForScreen(Niri.focusedScreen).increaseBrightness();
        }

        function down() {
            BrightnessService.getMonitorForScreen(Niri.focusedScreen).decreaseBrightness();
        }

        target: "brightness"
    }

    IpcHandler {
        function openRecent() {
            NotesService.openRecent();
        }

        function create() {
            NotesService.createNote();
        }

        target: "notes"
    }

}
