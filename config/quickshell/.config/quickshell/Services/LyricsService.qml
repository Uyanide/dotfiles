import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property bool isFetchingLyrics: false
    // Lyrics state
    // { "time": 0, "line": "lyric line" }
    // time is in ms
    property ListModel lyrics
    property int lyricsOffset: 0 // in ms
    property int currentIndex: -1
    // Player state
    // this property will be updated regardless of shouldRun for simplicity
    property int internalPosition: 0
    // Reference counting
    property var _registered: ({
    })
    readonly property int _registeredCount: Object.keys(_registered).length
    readonly property bool shouldRun: MediaService.currentPlayer && _registeredCount > 0
    // readonly property bool shouldRun: MediaService.currentPlayer !== null
    // Bar state
    readonly property bool showLyricsBar: ShellState.lyricsState.showLyricsBar || false

    signal lyricsUpdated()

    function registerComponent(componentId) {
        root._registered[componentId] = true;
        root._registered = Object.assign({
        }, root._registered);
        Logger.d("Lyrics", "Component registered:", componentId, "- total:", root._registeredCount);
    }

    function unregisterComponent(componentId) {
        delete root._registered[componentId];
        root._registered = Object.assign({
        }, root._registered);
        Logger.d("Lyrics", "Component unregistered:", componentId, "- total:", root._registeredCount);
    }

    function _requestFetchLyrics() {
        if (!root.shouldRun)
            return ;

        fetchLyricsTimer.restart();
    }

    function fetchLyrics() {
        root.lyrics.clear();
        root.lyricsUpdated();
        root.currentIndex = -1;
        if (!root.shouldRun)
            return ;

        root.isFetchingLyrics = true;
        if (!MediaService.currentPlayer?.identity) {
            root.isFetchingLyrics = false;
            return ;
        } else {
            lyricsProcess.request(MediaService.currentPlayer.identity.toLowerCase());
        }
    }

    function parseLRC(text) {
        if (!root.shouldRun)
            return ;

        // Logger.d("Lyrics", "Parsing :\n" + text);
        const lines = text.split("\n");
        let newLyrics = [];
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.length === 0)
                continue;

            const lyricLine = line.replace(/\[.*?]/g, "").trim();
            const regex = /\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?]/g;
            let match;
            while ((match = regex.exec(line)) !== null) {
                const minutes = parseInt(match[1], 10);
                const seconds = parseInt(match[2], 10);
                const milliseconds = match[3] ? parseInt(match[3].padEnd(3, "0"), 10) : 0;
                const time = minutes * 60 * 1000 + seconds * 1000 + milliseconds;
                newLyrics.push({
                    "time": time,
                    "line": lyricLine
                });
            }
        }
        newLyrics.sort((a, b) => {
            return a.time - b.time;
        });
        root.lyrics.clear();
        root.lyrics.append(newLyrics);
        root.isFetchingLyrics = false;
        root.lyricsUpdated();
        updateIndex();
    }

    function updateIndex() {
        if (!root.shouldRun)
            return ;

        if (root.lyrics.count === 0) {
            if (root.currentIndex !== -1)
                root.currentIndex = -1;

            return ;
        }
        const effectiveTime = root.internalPosition + root.lyricsOffset;
        let low = 0;
        let high = root.lyrics.count - 1;
        let bestMatch = -1;
        while (low <= high) {
            let mid = (low + high) >> 1;
            let midTime = root.lyrics.get(mid).time;
            if (midTime <= effectiveTime) {
                bestMatch = mid;
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        if (root.currentIndex !== bestMatch)
            root.currentIndex = bestMatch;

    }

    function increaseOffset() {
        root.lyricsOffset += 500;
    }

    function decreaseOffset() {
        root.lyricsOffset -= 500;
    }

    function resetOffset() {
        if (root.lyricsOffset !== 0)
            root.lyricsOffset = 0;

    }

    function toggleLyricsBar() {
        ShellState.lyricsState = {
            "showLyricsBar": !ShellState.lyricsState.showLyricsBar
        };
    }

    function seekToLyric(index) {
        if (index < 0 || index >= root.lyrics.count)
            return ;

        const time = root.lyrics.get(index).time - root.lyricsOffset;
        MediaService.seek(time / 1000);
    }

    onShouldRunChanged: {
        Logger.d("Lyrics", "Should run changed:", root.shouldRun);
        if (!root.shouldRun) {
            root.lyrics.clear();
            root.lyricsUpdated();
            root.currentIndex = -1;
        } else {
            root._requestFetchLyrics();
        }
    }
    onInternalPositionChanged: updateIndex()
    onLyricsOffsetChanged: updateIndex()

    Connections {
        function onCurrentPlayerChanged() {
            _requestFetchLyrics();
        }

        function onTrackTitleChanged() {
            _requestFetchLyrics();
        }

        function onTrackArtistChanged() {
            _requestFetchLyrics();
        }

        function onTrackAlbumChanged() {
            _requestFetchLyrics();
        }

        function onCurrentPositionChanged() {
            root.internalPosition = MediaService.currentPosition * 1000;
            if (shouldRun && MediaService.isPlaying)
                updateInternalTimer.restart();

        }

        target: MediaService
    }

    Timer {
        id: fetchLyricsTimer

        interval: 100
        repeat: false
        running: false
        onTriggered: fetchLyrics()
    }

    Process {
        id: lyricsProcess

        property string queuedPlayer: ""

        function request(player) {
            this.queuedPlayer = player;
            if (this.running)
                this.running = false;
            else
                handleQueue();
        }

        function handleQueue() {
            if (!this.queuedPlayer) {
                root.isFetchingLyrics = false;
                return ;
            }
            const player = this.queuedPlayer.toLowerCase();
            this.queuedPlayer = "";
            this.command = ["lrcfetch", "fetch", "--player", player];
            this.running = true;
        }

        running: false
        onExited: (exitCode, exitStatus) => {
            if (this.queuedPlayer)
                Qt.callLater(handleQueue);
            else
                root.isFetchingLyrics = false;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseLRC(this.text);
            }
        }

    }

    Timer {
        id: updateInternalTimer

        interval: 50
        repeat: true
        running: shouldRun && MediaService.isPlaying
        onTriggered: {
            root.internalPosition += this.interval;
        }
    }

    lyrics: ListModel {
    }

}
