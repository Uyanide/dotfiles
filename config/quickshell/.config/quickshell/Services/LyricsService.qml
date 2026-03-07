import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property int linesCount: 3
    property int linesAhead: linesCount / 2
    readonly property int currentIndex: linesCount - linesAhead - 1
    readonly property string offsetFile: Paths.cacheDir + "/spotify-lyrics-offset.txt"
    property int offset: 0 // in ms
    readonly property int offsetStep: 500 // in ms
    property int referenceCount: 0
    // with linesCount=3 and linesAhead=1, lyrics will be like:
    //   line 1
    //   line 2 <- current line
    //   line 3
    property var lyrics: Array(linesCount).fill(" ")
    readonly property bool showLyricsBar: ShellState.lyricsState.showLyricsBar || false

    function toggleLyricsBar() {
        ShellState.lyricsState = {
            "showLyricsBar": !root.showLyricsBar
        };
    }

    function startSyncing() {
        referenceCount++;
        Logger.d("LyricsService", "Reference count:", referenceCount);
        if (referenceCount === 1) {
            Logger.d("LyricsService", "Starting lyrics syncing");
            // fill lyrics with empty lines
            lyrics = Array(linesCount).fill(" ");
            listenProcess.exec(["sh", "-c", `pkill -x spotify-lyrics -u $USER; spotify-lyrics listen -l ${linesCount} -a ${linesAhead} -f ${offsetFile}`]);
        }
    }

    function stopSyncing() {
        referenceCount--;
        Logger.d("LyricsService", "Reference count:", referenceCount);
        if (referenceCount <= 0) {
            Logger.d("LyricsService", "Stopping lyrics syncing");
            // kinda ugly but works, meanwhile:
            //   listenProcess.signal(9)
            //   listenProcess.signal(15)
            //   listenProcess.running = false
            //   counting on exec() to terminate previous exec()
            // all don't work
            listenProcess.exec(["sh", "-c", `pkill -x spotify-lyrics -u $USER`]);
        }
    }

    function writeOffset() {
        offsetFileView.setText(String(offset));
    }

    function increaseOffset() {
        offset += offsetStep;
        saveState();
    }

    function decreaseOffset() {
        offset -= offsetStep;
        saveState();
    }

    function resetOffset() {
        offset = 0;
        saveState();
    }

    function clearCache() {
        action.command = ["sh", "-c", "spotify-lyrics clear $(spotify-lyrics trackid)"];
        action.startDetached();
    }

    function showLyricsText() {
        action.command = ["sh", "-c", "wezterm start -- sh -c 'spotify-lyrics fetch 2>/dev/null | less'"];
        action.startDetached();
    }

    onOffsetChanged: {
        if (root.showLyricsBar)
            SendNotification.show("Lyrics Offset Changed", `Current offset: ${offset} ms`);

        writeOffset();
    }

    Process {
        id: listenProcess

        running: false

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                lyrics = data.split("\n").slice(0, linesCount);
                if (lyrics.length < linesCount) {
                    // fill with empty lines if not enough
                    for (let i = lyrics.length; i < linesCount; i++) {
                        lyrics[i] = " ";
                    }
                }
            }
        }

    }

    Process {
        id: action

        running: false
    }

    FileView {
        id: offsetFileView

        path: offsetFile
        watchChanges: false
        onLoaded: {
            try {
                const fileContents = text();
                if (fileContents.length > 0) {
                    const val = parseInt(fileContents);
                    if (!isNaN(val)) {
                        offset = val;
                        Logger.d("LyricsService", "Loaded offset:", offset);
                    } else {
                        offset = 0;
                        writeOffset();
                    }
                } else {
                    offset = 0;
                    writeOffset();
                }
            } catch (e) {
                Logger.e("LyricsService", "Error reading offset file:", e);
            }
        }
        onLoadFailed: {
            Logger.e("LyricsService", "Error loading offset file.");
        }
        onSaveFailed: {
            Logger.e("LyricsService", "Error saving offset file.");
        }
    }

}
