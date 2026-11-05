import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils

Item {
    id: root

    property real fetchTimeout: 10 // in seconds
    property string fetchedData: ""
    property var fetchingCallback: null

    function fetch(url, callback, forceIPv4 = false) {
        if (curlProcess.running) {
            Logger.w("NetworkFetch", "A fetch operation is already in progress.");
            return ;
        }
        fetchedData = "";
        fetchingCallback = callback;
        curlProcess.command = ["curl", "-s", "-L", "-m", fetchTimeout.toString()];
        if (forceIPv4)
            curlProcess.command.push("-4");

        curlProcess.command.push(url);
        curlProcess.running = true;
    }

    Process {
        id: curlProcess

        running: false
        onStarted: {
            Logger.d("NetworkFetch", "Process started with command: " + curlProcess.command.join(" "));
        }
        onExited: function(exitCode, exitStatus) {
            if (!fetchingCallback) {
                Logger.e("NetworkFetch", "No callback defined for fetch operation.");
                return ;
            }
            if (exitCode === 0) {
                Logger.d("NetworkFetch", "Fetched data: " + fetchedData);
                fetchingCallback(true, fetchedData);
            } else {
                Logger.e("NetworkFetch", "Fetch failed with exit code: " + exitCode);
                fetchingCallback(false, "");
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                fetchedData += data;
            }
        }

    }

}
