import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils

Item {
    id: root

    property real fetchTimeout: 10 // in seconds
    property string fetchedData: ""
    property var fetchingCallback: null

    function fetch(url, callback) {
        if (curlProcess.running) {
            Logger.log("NetworkFetch", "A fetch operation is already in progress.");
            return ;
        }
        fetchedData = "";
        fetchingCallback = callback;
        curlProcess.command = ["curl", "-s", "-L", "-m", fetchTimeout.toString(), url];
        curlProcess.running = true;
    }

    function fakeFetch(resp, callback) {
        if (curlProcess.running) {
            Logger.log("NetworkFetch", "A fetch operation is already in progress.");
            return ;
        }
        fetchedData = "";
        fetchingCallback = callback;
        curlProcess.command = ["echo", resp];
        curlProcess.running = true;
    }

    Process {
        id: curlProcess

        running: false
        onStarted: {
            Logger.log("NetworkFetch", "Process started with command: " + curlProcess.command.join(" "));
        }
        onExited: function(exitCode, exitStatus) {
            if (!fetchingCallback) {
                Logger.error("NetworkFetch", "No callback defined for fetch operation.");
                return ;
            }
            if (exitCode === 0) {
                Logger.log("NetworkFetch", "Fetch completed successfully.");
                Logger.log("NetworkFetch", "Fetched data: " + fetchedData);
                fetchingCallback(true, fetchedData);
            } else {
                Logger.error("NetworkFetch", "Fetch failed with exit code: " + exitCode);
                fetchingCallback(false, "");
            }
        }

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                fetchedData += data;
            }
        }

    }

}
