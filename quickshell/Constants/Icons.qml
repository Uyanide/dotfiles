import QtQuick
import Quickshell
import qs.Utils
pragma Singleton

Singleton {
    id: root

    // Nerd fonts icons
    readonly property string distro: "󰣇"
    readonly property string tray: ""
    readonly property string idleInhibitorActivated: ""
    readonly property string idleInhibitorDeactivated: ""
    readonly property string powerMenu: "󰐥"
    readonly property string volumeHigh: ""
    readonly property string volumeMedium: ""
    readonly property string volumeLow: ""
    readonly property string volumeMuted: "󰝟"
    readonly property string brightness: ""
    readonly property string charging: ""
    readonly property string battery100: ""
    readonly property string battery75: ""
    readonly property string battery50: ""
    readonly property string battery25: ""
    readonly property string battery00: ""
    readonly property string cpu: "󰘚"
    readonly property string memory: "󰍛"
    readonly property string tempHigh: ""
    readonly property string tempMedium: ""
    readonly property string tempLow: ""
    readonly property string global: ""
    readonly property string upload: ""
    readonly property string download: ""
    readonly property string speedSlower: "󰾆"
    readonly property string speedFaster: "󰓅"
    readonly property string speedReset: "󰾅"
    readonly property string reset: "󰑙"
    readonly property string lines: ""
    // Expose the font family name for easy access
    readonly property string fontFamily: currentFontLoader ? currentFontLoader.name : ""
    readonly property string defaultIcon: TablerIcons.defaultIcon
    readonly property var icons: TablerIcons.icons
    readonly property var aliases: TablerIcons.aliases
    readonly property string fontPath: "/Assets/Fonts/tabler/tabler-icons.ttf"
    // Current active font loader
    property FontLoader currentFontLoader: null
    property int fontVersion: 0
    // Create a unique cache-busting path
    readonly property string cacheBustingPath: Quickshell.shellDir + fontPath + "?v=" + fontVersion + "&t=" + Date.now()

    // Signal emitted when font is reloaded
    signal fontReloaded()

    // ---------------------------------------
    function get(iconName) {
        // Check in aliases first
        if (aliases[iconName] !== undefined)
            iconName = aliases[iconName];

        // Find the appropriate codepoint
        return icons[iconName];
    }

    function loadFontWithCacheBusting() {
        // Destroy old loader first
        if (currentFontLoader) {
            currentFontLoader.destroy();
            currentFontLoader = null;
        }
        // Create new loader with cache-busting URL
        currentFontLoader = Qt.createQmlObject(`
                                           import QtQuick
                                           FontLoader {
                                           source: "${cacheBustingPath}"
                                           }
                                           `, root, "dynamicFontLoader_" + fontVersion);
        // Connect to the new loader's status changes
        currentFontLoader.statusChanged.connect(function() {
            if (currentFontLoader.status === FontLoader.Ready)
                fontReloaded();
            else if (currentFontLoader.status === FontLoader.Error)
                Logger.error("Icons", "Font failed to load (version " + fontVersion + ")");
        });
    }

    function reloadFont() {
        fontVersion++;
        loadFontWithCacheBusting();
    }

    Component.onCompleted: {
        loadFontWithCacheBusting();
    }

    Connections {
        function onReloadCompleted() {
            reloadFont();
        }

        target: Quickshell
    }

}
