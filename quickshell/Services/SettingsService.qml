import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services
pragma Singleton

Singleton {
    property alias primaryColor: adapter.primaryColor
    property alias showLyricsBar: adapter.showLyricsBar
    property string settingsFilePath: Qt.resolvedUrl("../Assets/Config/Settings.json")

    FileView {
        id: settingsFile

        path: settingsFilePath
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property string primaryColor: "#89b4fa"
            property bool showLyricsBar: false
        }

    }

    Connections {
        target: adapter
        onPrimaryColorChanged: settingsFile.writeAdapter()
        onShowLyricsBarChanged: settingsFile.writeAdapter()
    }

}
