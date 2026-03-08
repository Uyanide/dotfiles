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
    property var _registered: ({
    })
    readonly property int _registeredCount: Object.keys(_registered).length
    readonly property bool shouldRun: _registeredCount > 0
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
        Logger.d("Lyrics", "Starting lyrics syncing");
        // fill lyrics with empty lines
        lyrics = Array(linesCount).fill(" ");
        listenProcess.exec(["sh", "-c", `pkill -x spotify-lyrics -u $USER; spotify-lyrics listen -l ${linesCount} -a ${linesAhead} -f ${offsetFile}`]);
    }

    function stopSyncing() {
        Logger.d("Lyrics", "Stopping lyrics syncing");
        // kinda ugly but works, meanwhile:
        //   listenProcess.signal(9)
        //   listenProcess.signal(15)
        //   listenProcess.running = false
        //   counting on exec() to terminate previous exec()
        // all don't work
        Quickshell.execDetached(["sh", "-c", `pkill -x spotify-lyrics -u $USER`]);
    }

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
    onShouldRunChanged: {
        if (shouldRun)
            startSyncing();
        else
            stopSyncing();
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
                        Logger.d("Lyrics", "Loaded offset:", offset);
                    } else {
                        offset = 0;
                        writeOffset();
                    }
                } else {
                    offset = 0;
                    writeOffset();
                }
            } catch (e) {
                Logger.e("Lyrics", "Error reading offset file:", e);
            }
        }
        onLoadFailed: {
            Logger.e("Lyrics", "Error loading offset file.");
        }
        onSaveFailed: {
            Logger.e("Lyrics", "Error saving offset file.");
        }
    }

}
