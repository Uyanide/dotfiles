import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    readonly property string recordingDir: Paths.recordingDir
    property bool isRecording: false
    property bool isStopping: false
    readonly property string codec: "libx264"
    readonly property string container: "mkv"
    readonly property string pixelFormat: "yuv420p"
    property string recordingDisplay: ""
    readonly property int framerate: 60
    readonly property var codecParams: Object.freeze(["preset=ultrafast", "crf=15", "tune=zerolatency", "color_range=tv"])
    readonly property var filterArgs: ""

    function getFilename() {
        var d = new Date();
        var year = d.getFullYear();
        var month = ("0" + (d.getMonth() + 1)).slice(-2);
        var day = ("0" + d.getDate()).slice(-2);
        var hours = ("0" + d.getHours()).slice(-2);
        var minutes = ("0" + d.getMinutes()).slice(-2);
        var seconds = ("0" + d.getSeconds()).slice(-2);
        return "recording_" + year + "-" + month + "-" + day + "_" + hours + "." + minutes + "." + seconds + "." + container;
    }

    function getAudioSink() {
        return AudioService.sink ? AudioService.sink.name + '.monitor' : null; // this works on my machine :)
    }

    function getVideoSource(callback) {
        return Niri.focusedOutput || null;
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
        recordProcess.filePath = recordingDir + getFilename();
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
        recordProcess.onErrorExit = function() {
            Logger.e("RecordService", "Recording process exited with an error.");
            SendNotification.show("Recording failed", "An error occurred while trying to record the screen.");
        };
        recordProcess.onNormalExit = function() {
            Logger.i("RecordService", "Recording stopped, file saved to: " + recordProcess.filePath);
            SendNotification.show("Recording stopped", recordProcess.filePath);
        };
        recordProcess.running = true;
        SendNotification.show("Recording started", "Recording to " + recordProcess.filePath);
    }

    Process {
        id: recordProcess

        property string filePath: ""
        property var onNormalExit: null
        property var onErrorExit: null

        running: false
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                Logger.i("RecordService", "Recording stopped successfully.");
                if (onNormalExit) {
                    onNormalExit();
                    onNormalExit = null;
                }
            } else {
                Logger.e("RecordService", "Recording process exited with error code: " + exitCode);
                if (onErrorExit) {
                    onErrorExit();
                    onErrorExit = null;
                }
            }
            isRecording = false;
            isStopping = false;
            recordingDisplay = "";
        }
    }

}
