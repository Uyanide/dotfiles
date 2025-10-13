import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    property alias ip: cacheFileAdapter.ip
    property string cacheFilePath: CacheService.ipCacheFile
    property string countryCode: "N/A"
    property real fetchInterval: 120 // in s
    property real fetchTimeout: 10 // in s
    property string ipURL: "https://api.uyanide.com/ip"
    property string geoURL: "https://api.ipinfo.io/lite/"
    property string geoURLToken: ""

    function fetchIP() {
        curl.fetch(ipURL, function(success, data) {
            if (success) {
                try {
                    const response = JSON.parse(data);
                    if (response && response.ip) {
                        let newIP = response.ip;
                        Logger.log("IpService", "Fetched IP: " + newIP);
                        if (newIP !== ip) {
                            ip = newIP;
                            fetchGeoInfo(true); // Fetch geo info only if IP has changed
                        }
                    } else {
                        ip = "N/A";
                        countryCode = "N/A";
                        Logger.error("IpService", "IP response does not contain 'ip' field");
                    }
                } catch (e) {
                    ip = "N/A";
                    countryCode = "N/A";
                    Logger.error("IpService", "Failed to parse IP response: " + e);
                }
            } else {
                ip = "N/A";
                countryCode = "N/A";
                Logger.error("IpService", "Failed to fetch IP");
            }
        });
    }

    function fetchGeoInfo(notify) {
        if (!ip || ip === "N/A") {
            countryCode = "N/A";
            return ;
        }
        let url = geoURL + ip;
        if (geoURLToken)
            url += "?token=" + geoURLToken;

        curl.fetch(url, function(success, data) {
            if (success) {
                try {
                    const response = JSON.parse(data);
                    if (response && response.country_code) {
                        let newCountryCode = response.country_code;
                        Logger.log("IpService", "Fetched country code: " + newCountryCode);
                        countryCode = newCountryCode;
                    } else {
                        countryCode = "N/A";
                        Logger.error("IpService", "Geo response does not contain 'country_code' field");
                    }
                    cacheFileAdapter.ip = ip;
                    cacheFileAdapter.geoInfo = response;
                } catch (e) {
                    countryCode = "N/A";
                    Logger.error("IpService", "Failed to parse geo response: " + e);
                }
            } else {
                countryCode = "N/A";
                Logger.error("IpService", "Failed to fetch geo info");
            }
            SendNotification.show("New IP", `IP: ${ip}\nCountry: ${countryCode}`);
            cacheFile.writeAdapter();
        });
    }

    function refresh() {
        fetchTimer.stop();
        ip = "N/A";
        fetchIP();
        fetchTimer.start();
    }

    Component.onCompleted: {
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
                ipMonitorDebounce.restart();
            }
        }

    }

    Timer {
        id: ipMonitorDebounce

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
            fetchTimer.stop();
            fetchIP();
            fetchTimer.start();
        }
    }

    FileView {
        id: tokenFile

        path: Qt.resolvedUrl("../Assets/Config/GeoInfoToken.txt")
        onLoaded: {
            geoURLToken = tokenFile.text();
            if (!geoURLToken)
                Logger.warn("IpService", "No token found for geoIP service, assuming none is required");

            fetchIP();
            fetchTimer.start();
        }
    }

    FileView {
        id: cacheFile

        path: cacheFilePath
        watchChanges: false
        onLoaded: {
            Logger.log("IpService", "Loaded IP from cache file: " + cacheFileAdapter.ip);
            if (cacheFileAdapter.geoInfo) {
                countryCode = cacheFileAdapter.geoInfo.country_code || cacheFileAdapter.country || "N/A";
                Logger.log("IpService", "Loaded country code from cache file: " + countryCode);
            }
        }

        JsonAdapter {
            id: cacheFileAdapter

            property string ip: "N/A"
            property var geoInfo: null
        }

    }

}
