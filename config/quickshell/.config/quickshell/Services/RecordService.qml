import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    // Enabling replay may consume noticeably more resources -
    // around 500MiB of RAM and 4% of CPU on my machine. Use with caution
    readonly property bool replayEnabled: false
    readonly property string recordingDir: Paths.recordingDir
    property bool isRecording: false
    property bool isReplayInitStarted: false
    property bool isReplayStarted: false
    property bool isStopping: false
    property bool isReplayStopping: false
    readonly property string codec: "libx264"
    readonly property string container: "mkv"
    readonly property string pixelFormat: "yuv420p"
    property string recordingDisplay: ""
    readonly property int replayDuration: 15
    readonly property int framerate: 60
    readonly property var codecParams: Object.freeze(["preset=ultrafast", "crf=15", "tune=zerolatency", "color_range=tv"])
    readonly property var filterArgs: ""

    function getFilename(prefix = "recording") {
        var d = new Date();
        var year = d.getFullYear();
        var month = ("0" + (d.getMonth() + 1)).slice(-2);
        var day = ("0" + d.getDate()).slice(-2);
        var hours = ("0" + d.getHours()).slice(-2);
        var minutes = ("0" + d.getMinutes()).slice(-2);
        var seconds = ("0" + d.getSeconds()).slice(-2);
        return prefix + "_" + year + "-" + month + "-" + day + "_" + hours + "." + minutes + "." + seconds + "." + container;
    }

    function getAudioSink() {
        return AudioService.sink ? AudioService.sink.name + '.monitor' : null; // this works on my machine :)
    }

    function getVideoSource(callback) {
        return Niri.focusedOutput || null;
    }

    function getPrimaryVideoSource() {
        for (const screen of Quickshell.screens) {
            if (screen.name === "DP-1")
                return screen.name;

        }
        return Quickshell.screens.length ? Quickshell.screens[0].name : null;
    }

    function startOrStop() {
        if (isRecording)
            stop();
        else
            start();
    }

    function stop() {
        if (!isRecording) {
            Logger.w("RecordService", "Not currently recording, cannot stop.");
            return ;
        }
        if (isStopping) {
            Logger.w("RecordService", "Already stopping, please wait.");
            return ;
        }
        isStopping = true;
        recordProcess.signal(15);
    }

    function start() {
        if (isRecording || isStopping) {
            Logger.w("RecordService", "Already recording, cannot start.");
            return ;
        }
        isRecording = true;
        const source = getVideoSource();
        if (!source) {
            SendNotification.show("Recording failed", "Could not determine which display to record from.");
            Logger.e("RecordService", "No recording source available.");
            return ;
        }
        recordingDisplay = source;
        const audioSink = getAudioSink();
        if (!audioSink) {
            SendNotification.show("Recording failed", "No audio sink available to record from.");
            Logger.e("RecordService", "No audio sink available.");
            return ;
        }
        recordProcess.filePath = recordingDir + getFilename("recording");
        recordProcess.command = ["wf-recorder", "--audio=" + audioSink, "-o", source, "--codec", codec, "--pixel-format", pixelFormat, "--framerate", framerate.toString(), "-f", recordProcess.filePath];
        for (const param of codecParams) {
            recordProcess.command.push("-p");
            recordProcess.command.push(param);
        }
        if (filterArgs !== "") {
            recordProcess.command.push("-F");
            recordProcess.command.push(filterArgs);
        }
        Logger.i("RecordService", "Starting recording with command: " + recordProcess.command.join(" "));
        recordProcess.running = true;
        SendNotification.show("Recording started", "Recording to " + recordProcess.filePath);
    }

    function startReplay() {
        if (isReplayStarted || isReplayStopping) {
            Logger.w("RecordService", "Replay buffer already active, cannot start.");
            return ;
        }
        isReplayStarted = true;
        const source = getPrimaryVideoSource();
        if (!source) {
            SendNotification.show("Replay buffer failed", "Could not determine which display to record from.");
            Logger.e("RecordService", "No recording source available for replay buffer.");
            return ;
        }
        const audioSink = getAudioSink();
        if (!audioSink) {
            SendNotification.show("Replay buffer failed", "No audio sink available to record from.");
            Logger.e("RecordService", "No audio sink available for replay buffer.");
            return ;
        }
        replayProcess.filePath = recordingDir + getFilename("replay");
        replayProcess.command = ["wf-recorder", "--history", replayDuration, "--audio=" + audioSink, "-o", source, "--codec", codec, "--pixel-format", pixelFormat, "--framerate", framerate.toString(), "-f", replayProcess.filePath];
        for (const param of codecParams) {
            replayProcess.command.push("-p");
            replayProcess.command.push(param);
        }
        if (filterArgs !== "") {
            replayProcess.command.push("-F");
            replayProcess.command.push(filterArgs);
        }
        Logger.i("RecordService", "Starting replay buffer with command: " + replayProcess.command.join(" "));
        replayProcess.running = true;
    }

    function stopReplay(save = true) {
        if (!isReplayStarted) {
            Logger.w("RecordService", "Replay buffer not active, cannot stop.");
            return ;
        }
        if (isReplayStopping) {
            Logger.w("RecordService", "Already stopping replay buffer, please wait.");
            return ;
        }
        isReplayStopping = true;
        replayStopTimeout.restart();
        if (save)
            replayProcess.signal(10);
        else
            replayProcess.signal(2);
    }

    Component.onDestruction: function() {
        if (recordProcess.running)
            recordProcess.running = false;

        if (replayProcess.running)
            replayProcess.signal(2);

    }

    Connections {
        function onSinkChanged() {
            if (!replayEnabled)
                return ;

            // if (!isReplayInitStarted && AudioService.sink) {
            //     Logger.i("RecordService", "Audio sink available, starting replay buffer.");
            //     startReplay();
            //     isReplayInitStarted = true;
            // }
            if (!AudioService.sink) {
                Logger.w("RecordService", "Audio sink lost.");
                return ;
            }
            if (isReplayStarted) {
                Logger.i("RecordService", "Audio sink changed, restarting replay buffer.");
                stopReplay(false);
            } else {
                Logger.i("RecordService", "Audio sink available, starting replay buffer.");
                startReplay();
            }
        }

        target: AudioService
    }

    Process {
        id: recordProcess

        property string filePath: ""

        running: false
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                Logger.i("RecordService", "Recording stopped successfully.");
                SendNotification.show("Recording stopped", "File saved to: " + filePath);
            } else {
                Logger.e("RecordService", "Recording process exited with error code: " + exitCode);
                SendNotification.show("Recording failed", "An error occurred while trying to record the screen.");
            }
            isRecording = false;
            isStopping = false;
            recordingDisplay = "";
        }
    }

    Process {
        id: replayProcess

        property string filePath: ""

        running: false
        onExited: function(exitCode, exitStatus) {
            replayStopTimeout.stop();
            if (exitCode === 0) {
                Logger.i("RecordService", "Replay buffer saved successfully.");
                SendNotification.show("Replay saved", "File saved to: " + filePath);
            } else {
                Logger.e("RecordService", "Replay process exited with error code: " + exitCode);
                SendNotification.show("Replay failed", "An error occurred while trying to record the replay buffer.");
            }
            isReplayStarted = false;
            isReplayStopping = false;
            replayRestartTimer.restart();
        }
    }

    Timer {
        id: replayRestartTimer

        interval: 1000
        repeat: false
        onTriggered: function() {
            if (!isReplayStarted && !isReplayStopping)
                startReplay();

        }
    }

    Timer {
        id: replayStopTimeout

        interval: 5000
        repeat: false
        onTriggered: function() {
            if (isReplayStopping) {
                Logger.w("RecordService", "Replay buffer did not stop in time, killing process.");
                replayProcess.running = false;
            }
        }
    }

}
