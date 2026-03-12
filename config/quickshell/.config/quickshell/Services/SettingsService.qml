import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
pragma Singleton

Singleton {
    id: root

    property string settingsFilePath: Paths.configDir + "settings.json"
    property alias geoInfoToken: adapter.geoInfoToken
    property alias ipAliases: adapter.ipAliases
    property alias location: adapter.location
    property alias latitude: adapter.latitude
    property alias longitude: adapter.longitude
    property alias backgroundPath: adapter.backgroundPath
    property alias cycleWallpapers: cycleSettings.wallpapers
    property alias cycleShuffle: cycleSettings.shuffle
    property alias cycleInterval: cycleSettings.interval
    property alias cycleEnabled: cycleSettings.enabled
    property bool isLoaded: false

    FileView {
        id: settingFile

        path: settingsFilePath
        watchChanges: true
        onFileChanged: {
            reload();
        }
        onAdapterUpdated: writeAdapter()
        onLoaded: isLoaded = true
        onLoadFailed: isLoaded = true // Will create on change

        JsonAdapter {
            id: adapter

            property string geoInfoToken: ""
            property var ipAliases: {
                "127.0.0.1": "localhost"
            }
            property string location: "New York"
            property string latitude: "43"
            property string longitude: "-75"
            property string backgroundPath: ""
            property JsonObject cycle: JsonObject {
                id: cycleSettings

                property list<string> wallpapers: []
                property bool shuffle: false
                property int interval: 900
                property bool enabled: true
            }
        }

    }

}
