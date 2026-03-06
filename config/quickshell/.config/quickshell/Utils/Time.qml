import QtQuick
import Quickshell
pragma Singleton

Singleton {
    id: root

    // Current date
    property var now: new Date()
    // Unix timestamp of the last update
    property real _lastUpdateTs: Date.now()
    // Returns a Unix Timestamp (in seconds)
    readonly property int timestamp: {
        return Math.floor(root.now / 1000);
    }
    // Timer state (for countdown/stopwatch)
    property bool timerRunning: false
    property bool timerStopwatchMode: false
    property int timerRemainingSeconds: 0
    property int timerTotalSeconds: 0
    property int timerElapsedSeconds: 0
    property bool timerSoundPlaying: false
    property int timerStartTimestamp: 0 // Unix timestamp when timer was started
    property int timerPausedAt: 0 // Value when paused (for resuming)

    // Signal emitted when a significant time jump is detected (e.g. system resume)
    signal resumed()

    // Formats a Date object into a YYYYMMDD-HHMMSS string.
    function getFormattedTimestamp(date) {
        if (!date)
            date = new Date();

        const year = date.getFullYear();
        // getMonth() is zero-based, so we add 1
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const seconds = String(date.getSeconds()).padStart(2, '0');
        return `${year}${month}${day}-${hours}${minutes}${seconds}`;
    }

    // Format an easy to read approximate duration ex: 4h 32m
    // Used to display the time remaining on the Battery widget, computer uptime, etc..
    function formatVagueHumanReadableDuration(totalSeconds) {
        if (typeof totalSeconds !== 'number' || totalSeconds < 0)
            return '0s';

        // Floor the input to handle decimal seconds
        totalSeconds = Math.floor(totalSeconds);
        const days = Math.floor(totalSeconds / 86400);
        const hours = Math.floor((totalSeconds % 86400) / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;
        const parts = [];
        if (days)
            parts.push(`${days}d`);

        if (hours)
            parts.push(`${hours}h`);

        if (minutes)
            parts.push(`${minutes}m`);

        // Only show seconds if no hours and no minutes
        if (!hours && !minutes)
            parts.push(`${seconds}s`);

        return parts.join(' ');
    }

    // Format a date into
    function formatRelativeTime(date) {
        if (!date)
            return "";

        const diff = Date.now() - date.getTime();
        if (diff < 60000)
            return "Just now";

        if (diff < 120000)
            return "1 minute ago";

        if (diff < 3.6e+06)
            return `${Math.floor(diff / 60000)} minutes ago`;

        if (diff < 7.2e+06)
            return "1 hour ago";

        if (diff < 8.64e+07)
            return `${Math.floor(diff / 3.6e+06)} hours ago`;

        if (diff < 1.728e+08)
            return "1 day ago";

        return `${Math.floor(diff / 8.64e+07)} days ago`;
    }

    Component.onCompleted: {
        // Start by syncing to the next second boundary
        var now = new Date();
        var msUntilNextSecond = 1000 - now.getMilliseconds();
        updateTimer.interval = msUntilNextSecond + 10; // +10ms buffer
        updateTimer.restart();
    }

    Timer {
        id: updateTimer

        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: {
            var newTime = new Date();
            var currentTs = newTime.getTime();
            // Detect time jump (e.g. system resume) - threshold: 5 seconds
            if (currentTs - root._lastUpdateTs > 5000) {
                Logger.i("Time", "Time jump detected (" + Math.round((currentTs - root._lastUpdateTs) / 1000) + "s) - likely system resume");
                root.resumed();
            }
            root._lastUpdateTs = currentTs;
            root.now = newTime;
            // Update timer if running
            if (root.timerRunning && root.timerStartTimestamp > 0) {
                const elapsedSinceStart = root.timestamp - root.timerStartTimestamp;
                if (root.timerStopwatchMode) {
                    root.timerElapsedSeconds = root.timerPausedAt + elapsedSinceStart;
                } else {
                    root.timerRemainingSeconds = root.timerTotalSeconds - elapsedSinceStart;
                    if (root.timerRemainingSeconds <= 0)
                        root.timerOnFinished();

                }
            }
            // Adjust next interval to sync with the start of the next second
            var msIntoSecond = newTime.getMilliseconds();
            if (msIntoSecond > 100) {
                // If we're more than 100ms into the second, adjust for next time
                updateTimer.interval = 1000 - msIntoSecond + 10;
                // +10ms buffer
                updateTimer.restart();
            } else {
                updateTimer.interval = 1000;
            }
        }
    }

}
