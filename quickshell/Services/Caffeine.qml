import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
pragma Singleton

Singleton {
    // "systemd", "wayland", or "auto"
    // systemd-inhibit not found, try Wayland tools
    // wayhibitor not found

    id: root

    property string reason: "Application request"
    property bool isInhibited: false
    property var activeInhibitors: []
    // Different inhibitor strategies
    property string strategy: "systemd"

    // Auto-detect the best strategy
    function detectStrategy() {
        if (strategy === "auto") {
            // Check if systemd-inhibit is available
            try {
                var systemdResult = Quickshell.execDetached(["which", "systemd-inhibit"]);
                strategy = "systemd";
                return ;
            } catch (e) {
            }
            try {
                var waylandResult = Quickshell.execDetached(["which", "wayhibitor"]);
                strategy = "wayland";
                return ;
            } catch (e) {
            }
            strategy = "systemd"; // Fallback to systemd even if not detected
        }
    }

    // Add an inhibitor
    function addInhibitor(id, reason = "Application request") {
        if (activeInhibitors.includes(id))
            return false;

        activeInhibitors.push(id);
        updateInhibition(reason);
        return true;
    }

    // Remove an inhibitor
    function removeInhibitor(id) {
        const index = activeInhibitors.indexOf(id);
        if (index === -1) {
            console.log("Inhibitor not found:", id);
            return false;
        }
        activeInhibitors.splice(index, 1);
        updateInhibition();
        return true;
    }

    // Update the actual system inhibition
    function updateInhibition(newReason = reason) {
        const shouldInhibit = activeInhibitors.length > 0;
        if (shouldInhibit === isInhibited)
            return ;

        // No change needed
        if (shouldInhibit)
            startInhibition(newReason);
        else
            stopInhibition();
    }

    // Start system inhibition
    function startInhibition(newReason) {
        reason = newReason;
        if (strategy === "systemd")
            startSystemdInhibition();
        else if (strategy === "wayland")
            startWaylandInhibition();
        else
            return ;
        isInhibited = true;
    }

    // Stop system inhibition
    function stopInhibition() {
        if (!isInhibited)
            return ;

        if (inhibitorProcess.running)
            inhibitorProcess.signal(15);

        // SIGTERM
        isInhibited = false;
    }

    // Systemd inhibition using systemd-inhibit
    function startSystemdInhibition() {
        inhibitorProcess.command = ["systemd-inhibit", "--what=idle", "--why=" + reason, "--mode=block", "sleep", "infinity"];
        inhibitorProcess.running = true;
    }

    // Wayland inhibition using wayhibitor or similar
    function startWaylandInhibition() {
        inhibitorProcess.command = ["wayhibitor"];
        inhibitorProcess.running = true;
    }

    // Manual toggle for user control
    function manualToggle() {
        if (activeInhibitors.includes("manual")) {
            removeInhibitor("manual");
            return false;
        } else {
            addInhibitor("manual", "Manually activated by user");
            return true;
        }
    }

    Component.onCompleted: {
        detectStrategy();
    }
    // Clean up on shutdown
    Component.onDestruction: {
        stopInhibition();
    }

    // Process for maintaining the inhibition
    Process {
        id: inhibitorProcess

        running: false
        onExited: function(exitCode, exitStatus) {
            if (isInhibited)
                isInhibited = false;

            console.log("Inhibitor process exited with code:", exitCode, "status:", exitStatus);
        }
        onStarted: function() {
            console.log("Inhibitor process started with strategy:", root.strategy);
        }
    }

}
