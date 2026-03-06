import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    property alias ip: cacheFileAdapter.ip
    readonly property string cacheFilePath: Paths.cacheDir + "ip.json"
    readonly property string aliasFilePath: Paths.configDir + "ip_alias.json"
    readonly property string geoinfoTokenFilePath: Paths.configDir + "geo_token.txt"
    property string countryCode: "N/A"
    property string alias: ""
    property real fetchInterval: 120 // in s
    property real fetchTimeout: 10 // in s
    readonly property string ipURL: "https://api.uyanide.com/ip"
    readonly property string geoURL: "https://api.ipinfo.io/lite/"
    property string geoURLToken: SettingsService.geoInfoToken

    function fetchIP() {
        curl.fetch(ipURL, function(success, data) {
            if (success) {
                try {
                    const response = JSON.parse(data);
                    if (response && response.ip) {
                        let newIP = response.ip;
                        Logger.d("IpService", "Fetched IP: " + newIP);
                        if (newIP !== ip) {
                            ip = newIP;
                            countryCode = "N/A";
                            fetchGeoInfo(true); // Fetch geo info only if IP has changed
                        }
                    } else {
                        Logger.e("IpService", "IP response does not contain 'ip' field");
                    }
                } catch (e) {
                    Logger.e("IpService", "Failed to parse IP response: " + e);
                }
            } else {
                Logger.e("IpService", "Failed to fetch IP");
            }
        }, true);
    }

    function fetchGeoInfo(notify) {
        if (!ip || ip === "N/A") {
            countryCode = "N/A";
            return ;
        }
        let url = geoURL + ip;
        if (geoURLToken)
            url += "?token=" + geoURLToken;

        cacheFileAdapter.geoInfo = null;
        curl.fetch(url, function(success, data) {
            if (success) {
                try {
                    const response = JSON.parse(data);
                    if (response && (response.country_code || response.country)) {
                        let newCountryCode = response.country_code || response.country;
                        Logger.d("IpService", "Fetched country code: " + newCountryCode);
                        countryCode = newCountryCode;
                    } else {
                        Logger.e("IpService", "Geo response does not contain 'country_code' field");
                    }
                    cacheFileAdapter.geoInfo = response;
                } catch (e) {
                    Logger.e("IpService", "Failed to parse geo response: " + e);
                }
            } else {
                Logger.e("IpService", "Failed to fetch geo info");
            }
            SendNotification.show("New IP", `IP: ${ip}\nCountry: ${countryCode}${alias ? `\nAlias: ${alias}` : ""}`);
            cacheFile.writeAdapter();
        });
    }

    function refresh() {
        ip = "N/A";
        countryCode = "N/A";
        fetchIPDebouncer.restart();
    }

    function updateAlias() {
        if (!ip || ip === "N/A") {
            alias = "";
            return ;
        }
        alias = "";
        if (SettingsService.ipAliases[ip]) {
            alias = SettingsService.ipAliases[ip];
            Logger.d("IpService", "Found alias for IP " + ip + ": " + alias);
        }
    }

    Component.onCompleted: () => {
        return updateAlias();
    }
    onIpChanged: () => {
        return updateAlias();
    }

    NetworkFetch {
        id: curl
    }

    Process {
        id: ipMonitor

        command: ["ip", "monitor", "address", "route"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: {
                fetchIPDebouncer.restart();
            }
        }

    }

    Timer {
        id: fetchIPDebouncer

        interval: 1000
        repeat: false
        running: false
        onTriggered: {
            fetchIP();
        }
    }

    Timer {
        id: fetchTimer

        interval: fetchInterval * 1000
        repeat: true
        running: true
        onTriggered: {
            fetchIPDebouncer.restart();
        }
    }

    FileView {
        id: cacheFile

        path: cacheFilePath
        watchChanges: false
        onLoaded: {
            Logger.d("IpService", "Loaded IP from cache file: " + cacheFileAdapter.ip);
            if (cacheFileAdapter.geoInfo) {
                countryCode = cacheFileAdapter.geoInfo.country_code || cacheFileAdapter.country || "N/A";
                Logger.d("IpService", "Loaded country code from cache file: " + countryCode);
            }
        }

        JsonAdapter {
            id: cacheFileAdapter

            property string ip: "N/A"
            property var geoInfo: null
        }

    }

}
