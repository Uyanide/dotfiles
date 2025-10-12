import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    property int linesCount: 3
    property int linesAhead: linesCount / 2
    property int currentIndex: linesCount - linesAhead - 1
    property string offsetFile: Qt.resolvedUrl("../Assets/Config/LyricsOffset.txt")
    property int offset: 0 // in ms
    property int offsetStep: 500 // in ms
    property int referenceCount: 0
    // with linesCount=3 and linesAhead=1, lyrics will be like:
    //   line 1
    //   line 2 <- current line
    //   line 3
    property var lyrics: Array(linesCount).fill(" ")

    function startSyncing() {
        referenceCount++;
        Logger.log("LyricsService", "Reference count:", referenceCount);
        if (referenceCount === 1) {
            Logger.log("LyricsService", "Starting lyrics syncing");
            // fill lyrics with empty lines
            lyrics = Array(linesCount).fill(" ");
            listenProcess.exec(["sh", "-c", `sl-wrap listen -l ${linesCount} -a ${linesAhead} -f ${offsetFile.slice(7)}`]);
        }
    }

    function stopSyncing() {
        referenceCount--;
        Logger.log("LyricsService", "Reference count:", referenceCount);
        if (referenceCount <= 0) {
            Logger.log("LyricsService", "Stopping lyrics syncing");
            // Execute again to stop
            // kinda ugly but works, but meanwhile:
            //   listenProcess.signal(9)
            //   listenProcess.signal(15)
            //   listenProcess.running = false
            //   counts on exec() to terminate previous exec()
            // all don't work
            listenProcess.exec(["sh", "-c", `sl-wrap trackid`]);
        }
    }

    function writeOffset() {
        offsetFileView.setText(String(offset));
    }

    function increaseOffset() {
        offset += offsetStep;
    }

    function decreaseOffset() {
        offset -= offsetStep;
    }

    function resetOffset() {
        offset = 0;
    }

    function clearCache() {
        action.command = ["sh", "-c", "spotify-lyrics clear $(spotify-lyrics trackid)"];
        action.startDetached();
    }

    function showLyricsText() {
        action.command = ["sh", "-c", "ghostty -e sh -c 'spotify-lyrics fetch | less'"];
        action.startDetached();
    }

    onOffsetChanged: {
        if (SettingsService.showLyricsBar)
            SendNotification.show("Lyrics Offset Changed", `Current offset: ${offset} ms`, 1000);

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
                        Logger.log("LyricsService", "Loaded offset:", offset);
                    } else {
                        offset = 0;
                        writeOffset();
                    }
                } else {
                    offset = 0;
                    writeOffset();
                }
            } catch (e) {
                Logger.log("LyricsService", "Error reading offset file:", e);
            }
        }
        onLoadFailed: {
            Logger.log("LyricsService", "Error loading offset file:", errorString);
        }
        onSaveFailed: {
            Logger.log("LyricsService", "Error saving offset file:", errorString);
        }
        onSaved: {
            Logger.log("LyricsService", "Offset file saved.");
        }
    }

}
