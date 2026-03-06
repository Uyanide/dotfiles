import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property double _latitude: -1
    property double _longitude: -1
    property int temperature: 0
    property bool isEnabled: ShellState.sunsetState.enabled || false

    function toggleSunset() {
        ShellState.sunsetState = {
            "enabled": !root.isEnabled
        };
    }

    function setLat(lat) {
        _latitude = lat;
        Logger.i("Sunset", "Updated latitude to " + lat);
        checkStart();
    }

    function setLong(lng) {
        _longitude = lng;
        Logger.i("Sunset", "Updated longitude to " + lng);
        checkStart();
    }

    function checkStart() {
        if (_latitude !== -1 && _longitude !== -1 && root.isEnabled) {
            sunsetProcess.command = ["wlsunset", "-l", _latitude.toString(), "-L", _longitude.toString()];
            sunsetProcess.running = true;
        }
    }

    Connections {
        function onLatitudeChanged() {
            Logger.d("");
            setLat(LocationService.data.latitude);
        }

        function onLongitudeChanged() {
            setLong(LocationService.data.longitude);
        }

        target: LocationService.data
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
