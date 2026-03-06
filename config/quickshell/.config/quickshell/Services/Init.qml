import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property bool loaded: false

    Component.onCompleted: {
        let mkdirs = "";
        for (const dir of [Paths.cacheDir, Paths.configDir, Paths.recordingDir]) {
            mkdirs += `mkdir -p "${dir}" && `;
        }
        mkdirs += "true";
        Logger.d("Init", `Creating necessary directories with command: ${mkdirs}`);
        process.command = ["sh", "-c", mkdirs];
        process.running = true;
    }

    Process {
        id: process

        running: false
        onExited: (code, status) => {
            if (code === 0)
                root.loaded = true;
            else
                Logger.e("Init", `Failed to create necessary directories: ${code} (${status})`);
        }
    }

}
