import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services

Item {
    IpcHandler {
        function startOrStopRecording() {
            RecordService.startOrStop();
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
        function previewWallpaper(path: string) {
            BackgroundService.previewWallpaper(path);
        }

        function setWallpaper(path: string) {
            BackgroundService.setWallpaper(path);
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
        function setColor(name: string, value: color) {
            Colors.setColor(name, value);
        }

        function unsetColor(name: string) {
            Colors.unsetColor(name);
        }

        function getColor(name: string) : string {
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
        function toggleInhibitor() {
            Caffeine.manualToggle();
        }

        target: "idleInhibitor"
    }

    IpcHandler {
        function toggleSunset() {
            SunsetService.toggleSunset();
        }

        target: "sunset"
    }

    IpcHandler {
        function brightnessUp() {
            BrightnessService.getMonitorForScreen(Niri.focusedScreen).increaseBrightness();
        }

        function brightnessDown() {
            BrightnessService.getMonitorForScreen(Niri.focusedScreen).decreaseBrightness();
        }

        target: "brightness"
    }

    IpcHandler {
        function openRecent() {
            NotesService.openRecent();
        }

        function createNote() {
            NotesService.createNote();
        }

        target: "notes"
    }

}
