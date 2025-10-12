import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Scope {
    id: root

    property int count: 32
    property int noiseReduction: 60
    property string channels: "mono"
    property string monoOption: "average"
    property var config: ({
        "general": {
            "bars": count,
            "framerate": 30,
            "autosens": 1
        },
        "smoothing": {
            "monstercat": 1,
            "gravity": 1e+06,
            "noise_reduction": noiseReduction
        },
        "output": {
            "method": "raw",
            "data_format": "ascii",
            "ascii_max_range": 100,
            "bit_format": "8bit",
            "channels": channels,
            "mono_option": monoOption
        }
    })
    property var values: Array(count).fill(0)

    Process {
        id: process

        stdinEnabled: true
        running: !MusicManager.isAllPaused()
        command: ["cava", "-p", "/dev/stdin"]
        onExited: {
            stdinEnabled = true;
            values = Array(count).fill(0);
        }
        onStarted: {
            for (const k in config) {
                if (typeof config[k] !== "object") {
                    write(k + "=" + config[k] + "\n");
                    continue;
                }
                write("[" + k + "]\n");
                const obj = config[k];
                for (const k2 in obj) {
                    write(k2 + "=" + obj[k2] + "\n");
                }
            }
            stdinEnabled = false;
            values = Array(count).fill(0);
        }

        stdout: SplitParser {
            onRead: (data) => {
                root.values = data.slice(0, -1).split(";").map((v) => {
                    return parseInt(v, 10) / 100;
                });
            }
        }

    }

}
