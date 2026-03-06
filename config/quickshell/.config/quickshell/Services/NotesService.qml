import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property string notesDir: Paths.cacheDir + "/notes"
    property var notes: []
    property ListModel notesModel

    function loadNotes() {
        listProcess.running = true;
    }

    function createNote() {
        var id = new Date().getTime().toString();
        var filePath = notesDir + "/" + id + ".txt";
        // Random color index from 0 to 7
        var colorIdx = Math.floor(Math.random() * 8);
        createProcess.command = ["sh", "-c", "mkdir -p " + notesDir + " && echo 'New Note' > " + filePath + " && echo " + colorIdx + " > " + filePath + ".color"];
        createProcess.running = true;
    }

    function deleteNote(id) {
        var filePath = notesDir + "/" + id + ".txt";
        var colorPath = notesDir + "/" + id + ".txt.color";
        deleteProcess.command = ["rm", "-f", filePath, colorPath];
        deleteProcess.running = true;
    }

    function openNote(id) {
        var filePath = notesDir + "/" + id + ".txt";
        openProcess.command = ["gnome-text-editor", filePath];
        openProcess.running = true;
    }

    Component.onCompleted: {
        loadNotes();
    }

    Process {
        id: openProcess
    }

    Process {
        id: createProcess

        onExited: root.loadNotes()
    }

    Process {
        id: deleteProcess

        onExited: root.loadNotes()
    }

    Process {
        id: listProcess

        command: ["sh", "-c", "mkdir -p " + notesDir + " && ls -1 " + notesDir + " | grep '\\.txt$' || true"]

        stdout: StdioCollector {
            id: listCollector

            onStreamFinished: {
                var files = listCollector.text.split('\n');
                notesModel.clear();
                for (var i = 0; i < files.length; i++) {
                    if (files[i] === "")
                        continue;

                    var id = files[i].replace(".txt", "");
                    var contentFile = notesDir + "/" + files[i];
                    var colorFile = notesDir + "/" + files[i] + ".color";
                    // create an intermediate reader process
                    readProcessComponent.createObject(root, {
                        "noteId": id,
                        "contentFile": contentFile,
                        "colorFile": colorFile
                    }).run();
                }
            }
        }

    }

    Component {
        id: readProcessComponent

        Process {
            id: p

            property string noteId
            property string contentFile
            property string colorFile

            function run() {
                running = true;
            }

            command: ["sh", "-c", "cat " + colorFile + " 2>/dev/null || echo 0; head -n 5 " + contentFile]

            stdout: StdioCollector {
                id: readCollector

                onStreamFinished: {
                    var lines = readCollector.text.split('\n');
                    var colorIdx = parseInt(lines[0] || "0");
                    lines.shift();
                    var contentLines = lines.join('\n').trim();
                    notesModel.append({
                        "noteId": p.noteId,
                        "title": contentLines,
                        "colorIdx": colorIdx
                    });
                    p.destroy();
                }
            }

        }

    }

    notesModel: ListModel {
    }

}
