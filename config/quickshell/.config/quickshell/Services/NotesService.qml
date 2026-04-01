import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property ListModel notesModel
    property string recentNotePath: ""

    function createNote() {
        if (createProcess.running) {
            Logger.w("Notes", "Create process is already running, skipping new note creation.");
            return ;
        }
        const fileName = generateFileName();
        const path = Paths.notesDir + "/" + fileName;
        createProcess.currentNote = {
            "notePath": path,
            "colorIdx": strToColor(fileName),
            "contentPreview": ""
        };
        createProcess.command = ["touch", path];
        createProcess.running = true;
    }

    function deleteNote(path) {
        if (deleteProcess.running) {
            Logger.w("Notes", "Delete process is already running, skipping note deletion.");
            return ;
        }
        deleteProcess.currentPath = path;
        deleteProcess.command = ["rm", "-f", path];
        deleteProcess.running = true;
    }

    function openNote(path) {
        recentNotePath = path;
        Quickshell.execDetached(["ghostty", "+new-window", "-e", "nvim", path]);
    }

    function openRecent() {
        if (recentNotePath)
            openNote(recentNotePath);
        else
            createNote();
    }

    function strToColor(str) {
        let hash = 5381;
        for (let i = 0; i < str.length; i++) {
            hash = ((hash << 5) + hash) + str.charCodeAt(i);
        }
        return hash >>> 0;
    }

    function generateFileName() {
        const timestamp = Time.timestamp;
        const randomPart = Math.floor(Math.random() * 1e+06);
        return `note_${timestamp}_${randomPart}.txt`;
    }

    Process {
        id: createProcess

        property var currentNote

        onExited: (ret) => {
            if (ret !== 0 || !currentNote) {
                Logger.e("Notes", `Failed to create note file: ${ret}`);
                return ;
            }
            root.notesModel.append(currentNote);
            const toOpen = currentNote.notePath;
            currentNote = null;
            root.openNote(toOpen);
        }
    }

    Process {
        id: deleteProcess

        property string currentPath

        onExited: (ret) => {
            if (ret !== 0) {
                Logger.e("Notes", `Failed to delete note file: ${ret}`);
                return ;
            }
            for (let i = 0; i < root.notesModel.count; i++) {
                if (root.notesModel.get(i).notePath === currentPath) {
                    root.notesModel.remove(i);
                    break;
                }
            }
            if (root.recentNotePath === currentPath)
                if (root.notesModel.count > 0)
                root.recentNotePath = root.notesModel.get(0).notePath;
            else
                root.recentNotePath = "";;

            currentPath = "";
        }
    }

    Process {
        id: initProcess

        running: true
        command: ["sh", "-c", "ls -p -t " + Paths.notesDir]

        stdout: StdioCollector {
            id: listCollector

            onStreamFinished: {
                const files = listCollector.text.split('\n');
                root.notesModel.clear();
                for (var i = 0; i < files.length; i++) {
                    const fileName = files[i].trim();
                    if (!fileName || !fileName.endsWith(".txt"))
                        continue;

                    root.notesModel.append({
                        "notePath": Paths.notesDir + "/" + fileName,
                        "colorIdx": strToColor(fileName),
                        "contentPreview": ""
                    });
                    Logger.d("Notes", "Loaded note: " + fileName);
                }
                if (root.notesModel.count > 0)
                    root.recentNotePath = root.notesModel.get(0).notePath;

            }
        }

    }

    Instantiator {
        model: notesModel

        delegate: FileView {
            path: model.notePath
            watchChanges: true
            onFileChanged: reload()
            onLoaded: {
                const content = text();
                if (!content)
                    model.contentPreview = "(empty note)";
                else
                    model.contentPreview = content.trim().split('\n').slice(0, 5).join('\n');
            }
        }

    }

    notesModel: ListModel {
    }

}
