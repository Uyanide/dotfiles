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
    property alias backgroundPath: adapter.backgroundPath
    property alias wifiEnabled: adapter.wifiEnabled
    property alias cycleWallpapers: cycleSettings.wallpapers
    property alias cycleShuffle: cycleSettings.shuffle
    property alias cycleInterval: cycleSettings.interval
    property alias cycleEnabled: cycleSettings.enabled

    FileView {
        id: settingFile

        path: settingsFilePath
        watchChanges: true
        onFileChanged: {
            reload();
        }
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter

            property string geoInfoToken: ""
            property var ipAliases: {
                "127.0.0.1": "localhost"
            }
            property string location: "New York"
            property string backgroundPath: ""
            property bool wifiEnabled: true
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
