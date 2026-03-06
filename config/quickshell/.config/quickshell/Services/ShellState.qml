import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property string stateFile: Paths.cacheDir + "shell-state.json"
    property bool isLoaded: false
    property alias notificationsState: adapter.notificationsState
    property alias lyricsState: adapter.lyricsState
    property alias sunsetState: adapter.sunsetState
    property alias leftSiderbarTab: adapter.leftSiderbarTab
    property alias rightSiderbarTab: adapter.rightSiderbarTab

    function save() {
        saveTimer.restart();
    }

    onNotificationsStateChanged: save()
    onLyricsStateChanged: save()
    onSunsetStateChanged: save()
    onLeftSiderbarTabChanged: save()
    onRightSiderbarTabChanged: save()
    Component.onCompleted: {
        stateFileView.path = stateFile;
    }

    FileView {
        id: stateFileView

        printErrors: false
        watchChanges: false
        onLoaded: {
            root.isLoaded = true;
            Logger.d("ShellState", "Loaded state file");
        }
        onLoadFailed: (error) => {
            root.isLoaded = true;
        }

        adapter: JsonAdapter {
            id: adapter

            property var notificationsState: ({
                "lastSeenTs": 0,
                "doNotDisturb": false
            })
            property var lyricsState: ({
                "showLyricsBar": false
            })
            property var sunsetState: ({
                "enabled": true
            })
            property string leftSiderbarTab: "bluetooth"
            property string rightSiderbarTab: "notes"
        }

    }

    Timer {
        id: saveTimer

        interval: 500
        onTriggered: {
            if (stateFile) {
                try {
                    stateFileView.writeAdapter();
                } catch (e) {
                }
            }
        }
    }

}
