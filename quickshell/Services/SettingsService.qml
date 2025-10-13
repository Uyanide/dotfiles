import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services
pragma Singleton

Singleton {
    property alias primaryColor: adapter.primaryColor
    property alias showLyricsBar: adapter.showLyricsBar
    property alias notifications: adapter.notifications
    property alias location: adapter.location
    property string settingsFilePath: Qt.resolvedUrl("../Assets/Config/Settings.json")

    FileView {
        id: settingsFile

        path: settingsFilePath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter

            property string primaryColor: "#89b4fa"
            property bool showLyricsBar: false
            property JsonObject notifications
            property string location: "New York"

            notifications: JsonObject {
                property bool doNotDisturb: false
                property real lastSeenTs: 0
            }

        }

    }

}
