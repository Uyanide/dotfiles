import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    property string ip: "N/A"
    property string countryCode: "N/A"
    property real fetchInterval: 30 // in s
    property real fetchTimeout: 10 // in s
    property string ipURL: "https://api.uyanide.com/ip"
    property string geoURL: "curl https://api.ipinfo.io/lite/"
    property string geoURLToken: ""

    function fetchIP() {
        if (fetchIPProcess.running) {
            console.warn("Fetch IP process is still running, skipping fetchIP");
            return ;
        }
        fetchIPProcess.running = true;
    }

    function fetchGeoInfo() {
        if (fetchGeoProcess.running) {
            console.warn("Fetch geo process is still running, skipping fetchGeoInfo");
            return ;
        }
        if (!ip || ip === "N/A") {
            countryCode = "N/A";
            return ;
        }
        fetchGeoProcess.command = ["sh", "-c", `curl -L -m ${fetchTimeout.toString()} ${geoURL}${ip}${geoURLToken ? "?token=" + geoURLToken : ""}`];
        fetchGeoProcess.running = true;
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

        path: Qt.resolvedUrl("../Assets/Ip/token.txt")
        onLoaded: {
            geoURLToken = tokenFile.text();
            if (!geoURLToken)
                console.warn("No token found for geoIP service, assuming none is required");

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

    Process {
        id: fetchIPProcess

        command: ["sh", "-c", `curl -L -m ${fetchTimeout.toString()} ${ipURL}`]
        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                let newIP = "";
                try {
                    const response = JSON.parse(data);
                    if (response && response.ip) {
                        newIP = response.ip;
                        console.log("Fetched IP: " + newIP);
                    }
                } catch (e) {
                    console.error("Failed to parse IP response: " + e);
                }
                if (newIP && newIP !== ip) {
                    ip = newIP;
                    fetchGeoInfo();
                } else if (!newIP) {
                    ip = "N/A";
                    countryCode = "N/A";
                }
            }
        }

    }

    Process {
        id: fetchGeoProcess

        command: []
        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                let newCountryCode = "";
                try {
                    const response = JSON.parse(data);
                    if (response && response.country) {
                        newCountryCode = response.country_code;
                        console.log("Fetched country code: " + newCountryCode);
                        SendNotification.show("New IP", `IP: ${ip}\nCountry: ${newCountryCode}`);
                    }
                } catch (e) {
                    console.error("Failed to parse geo response: " + e);
                }
                if (newCountryCode && newCountryCode !== countryCode)
                    countryCode = newCountryCode;
                else if (!newCountryCode)
                    countryCode = "N/A";
            }
        }

    }

}
