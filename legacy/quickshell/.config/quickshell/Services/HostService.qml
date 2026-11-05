import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property string username: Quickshell.env("USER") || "user"
    property string hostname: "--"
    property string uptimeText: "--"

    Process {
        id: usernameProcess

        command: ["whoami"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.username = this.text.trim();
                usernameProcess.running = false;
            }
        }

    }

    Process {
        id: hostnameProcess

        command: ["cat", "/etc/hostname"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.hostname = this.text.trim();
                hostnameProcess.running = false;
            }
        }

    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: uptimeProcess.running = true
    }

    Process {
        id: uptimeProcess

        command: ["cat", "/proc/uptime"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var uptimeSeconds = parseFloat(this.text.trim().split(' ')[0]);
                root.uptimeText = Time.formatVagueHumanReadableDuration(uptimeSeconds);
                uptimeProcess.running = false;
            }
        }

    }

}
