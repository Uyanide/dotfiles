import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property bool defaultRunning: SettingsService.sunsetDefaultEnabled
    property double _latitude: -1
    property double _longitude: -1
    property alias isRunning: sunsetProcess.running
    property int temperature: 0

    function startSunset() {
        if (isRunning)
            return ;

        if (_latitude == -1 || _longitude == -1) {
            Logger.warn("Sunset", "Cannot start sunset process, invalid coordinates");
            return ;
        }
        sunsetProcess.command = ["wlsunset", "-l", _latitude.toString(), "-L", _longitude.toString()];
        sunsetProcess.running = true;
    }

    function stopSunset() {
        if (!isRunning)
            return ;

        sunsetProcess.running = false;
    }

    function toggleSunset() {
        if (isRunning)
            stopSunset();
        else
            startSunset();
    }

    function setLat(lat) {
        _latitude = lat;
        Logger.log("Sunset", "Updated latitude to " + lat);
        checkStart();
    }

    function setLong(lng) {
        _longitude = lng;
        Logger.log("Sunset", "Updated longitude to " + lng);
        checkStart();
    }

    function checkStart() {
        if (_latitude != -1 && _longitude != -1 && defaultRunning && !isRunning)
            startSunset();

    }

    Connections {
        target: LocationService.data
        onLatitudeChanged: {
            setLat(LocationService.data.latitude);
        }
        onLongitudeChanged: {
            setLong(LocationService.data.longitude);
        }
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
                    Logger.log("Sunset", "Updated temperature to " + temperature + " K");
                }
            }
        }

    }

    NetworkFetch {
        id: curl
    }

}
