import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants

Item {
    IpcHandler {
        function setPrimary(color: color) {
            SettingsService.primaryColor = color;
        }

        target: "colors"
    }

    IpcHandler {
        function toggleCalendar() {
            calendarPanel.toggle();
        }

        function toggleControlCenter() {
            controlCenterPanel.toggle();
        }

        target: "panels"
    }

    IpcHandler {
        function toggleBarLyrics() {
            SettingsService.showLyricsBar = !SettingsService.showLyricsBar;
        }

        target: "lyrics"
    }

    IpcHandler {
        function toggleInhibitor() {
            Caffeine.manualToggle();
        }

        target: "idleInhibitor"
    }

    IpcHandler {
        function startOrStopRecording() {
            RecordService.startOrStop();
        }

        target: "recording"
    }

    IpcHandler {
        function toggleSunset() {
            SunsetService.toggleSunset();
        }

        target: "sunset"
    }

}
