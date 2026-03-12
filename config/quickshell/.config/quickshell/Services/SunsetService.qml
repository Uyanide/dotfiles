import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property string _latitude: SettingsService.latitude
    property string _longitude: SettingsService.longitude
    property int temperature: 0
    readonly property bool isEnabled: ShellState.sunsetEnabled

    function toggleSunset() {
        ShellState.sunsetEnabled = !root.isEnabled;
    }

    function checkStart() {
        if (_latitude !== "" && _longitude !== "" && root.isEnabled) {
            sunsetProcess.command = ["wlsunset", "-l", _latitude, "-L", _longitude];
            sunsetProcess.running = true;
        } else if (root.isEnabled) {
            Logger.w("Sunset", "Missing coordinates, starting wlsunset without location");
            sunsetProcess.command = ["wlsunset"];
            sunsetProcess.running = true;
        }
    }

    Connections {
        function onIsEnabledChanged() {
            if (root.isEnabled)
                checkStart();
            else
                sunsetProcess.running = false;
        }

        target: root
    }

    Connections {
        function onRunningChanged() {
            if (!sunsetProcess.running) {
                temperature = 0;
                Logger.i("Sunset", "Stopped sunset process");
            } else {
                Logger.i("Sunset", "Started sunset process");
            }
        }

        target: sunsetProcess
    }

    Process {
        id: sunsetProcess

        running: false

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                // console.log(line);
                var tempMatch = line.match(/setting temperature to (\d+) K/);
                if (tempMatch && tempMatch.length == 2) {
                    temperature = parseInt(tempMatch[1]);
                    Logger.d("Sunset", "Updated temperature to " + temperature + " K");
                }
            }
        }

    }

}
