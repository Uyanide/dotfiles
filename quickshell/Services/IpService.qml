import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
pragma Singleton

Singleton {
    property string ip: "N/A"
    property string countryCode: "N/A"
    property real fetchInterval: 30 // in s
    property real fetchTimeout: 10 // in s
    property string ipURL: "https://api.uyanide.com/ip"
    property string geoURL: "https://api.ipinfo.io/lite/"
    property string geoURLToken: ""

    function fetchIP() {
        const xhr = new XMLHttpRequest();
        xhr.timeout = fetchTimeout * 1000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        if (response && response.ip) {
                            let newIP = response.ip;
                            Logger.log("IpService", "Fetched IP: " + newIP);
                            if (newIP !== ip) {
                                ip = newIP;
                                fetchGeoInfo(); // Fetch geo info only if IP has changed
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
                    Logger.error("IpService", "Failed to fetch IP, status: " + xhr.status);
                }
            }
        };
        xhr.ontimeout = function() {
            ip = "N/A";
            countryCode = "N/A";
            Logger.error("IpService", "Fetch IP request timed out");
        };
        xhr.open("GET", ipURL);
        xhr.send();
    }

    function fetchGeoInfo() {
        if (!ip || ip === "N/A") {
            countryCode = "N/A";
            return ;
        }
        const xhr = new XMLHttpRequest();
        xhr.timeout = fetchTimeout * 1000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        if (response && response.country) {
                            let newCountryCode = response.country_code;
                            Logger.log("IpService", "Fetched country code: " + newCountryCode);
                            if (newCountryCode !== countryCode) {
                                countryCode = newCountryCode;
                                SendNotification.show("New IP", `IP: ${ip}\nCountry: ${newCountryCode}`);
                            }
                        } else {
                            countryCode = "N/A";
                            Logger.error("IpService", "Geo response does not contain 'country' field");
                        }
                    } catch (e) {
                        countryCode = "N/A";
                        Logger.error("IpService", "Failed to parse geo response: " + e);
                    }
                } else {
                    countryCode = "N/A";
                    Logger.error("IpService", "Failed to fetch geo info, status: " + xhr.status);
                }
            }
        };
        xhr.ontimeout = function() {
            countryCode = "N/A";
            Logger.error("IpService", "Fetch geo info request timed out");
        };
        let url = geoURL + ip;
        if (geoURLToken)
            url += "?token=" + geoURLToken;

        xhr.open("GET", url);
        xhr.send();
    }

    function refresh() {
        fetchTimer.stop();
        ip = "N/A";
        fetchIP();
        fetchTimer.start();
    }

    Component.onCompleted: {
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

    Timer {
        id: fetchTimer

        interval: fetchInterval * 1000
        repeat: true
        running: false
        onTriggered: {
            fetchIP();
        }
    }

}
