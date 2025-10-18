import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    property string recordingDir: CacheService.recordingDir
    property bool isRecording: false
    property bool isStopping: false
    property string codec: "av1_nvenc"
    property string container: "mkv"
    property string pixelFormat: "p010le"
    property string recordingDisplay: ""
    property int framerate: 60
    property var codecParams: ["preset=p5", "rc=vbr", "cq=18", "b:v=80M", "maxrate=120M", "bufsize=160M", "color_range=tv"]
    property var filterArgs: []

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
        if (niriFocusedOutputProcess.running) {
            Logger.warn("RecordService", "Already fetching focused output, returning null.");
            callback(null);
        }
        niriFocusedOutputProcess.onGetName = callback;
        niriFocusedOutputProcess.running = true;
    }

    function startOrStop() {
        if (isRecording)
            stop();
        else
            start();
    }

    function stop() {
        if (!isRecording) {
            Logger.warn("RecordService", "Not currently recording, cannot stop.");
            return ;
        }
        if (isStopping) {
            Logger.warn("RecordService", "Already stopping, please wait.");
            return ;
        }
        isStopping = true;
        recordProcess.signal(15);
    }

    function start() {
        if (isRecording || isStopping) {
            Logger.warn("RecordService", "Already recording, cannot start.");
            return ;
        }
        isRecording = true;
        getVideoSource((source) => {
            if (!source) {
                SendNotification.show("Recording failed", "Could not determine which display to record from.");
                return ;
            }
            recordingDisplay = source;
            const audioSink = getAudioSink();
            if (!audioSink) {
                SendNotification.show("Recording failed", "No audio sink available to record from.");
                return ;
            }
            recordProcess.filePath = recordingDir + getFilename();
            recordProcess.command = ["wf-recorder", "--audio=" + audioSink, "-o", source, "--codec", codec, "--pixel-format", pixelFormat, "--framerate", framerate.toString(), "-f", recordProcess.filePath];
            for (const param of codecParams) {
                recordProcess.command.push("-p");
                recordProcess.command.push(param);
            }
            for (const filter of filterArgs) {
                recordProcess.command.push("-F");
                recordProcess.command.push(filter);
            }
            Logger.log("RecordService", "Starting recording with command: " + recordProcess.command.join(" "));
            recordProcess.onErrorExit = function() {
                SendNotification.show("Recording failed", "An error occurred while trying to record the screen.");
            };
            recordProcess.onNormalExit = function() {
                SendNotification.show("Recording stopped", recordProcess.filePath);
            };
            recordProcess.running = true;
            SendNotification.show("Recording started", "Recording to " + recordProcess.filePath);
        });
    }

    Process {
        id: recordProcess

        property string filePath: ""
        property var onNormalExit: null
        property var onErrorExit: null

        running: false
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                Logger.log("RecordService", "Recording stopped successfully.");
                if (onNormalExit) {
                    onNormalExit();
                    onNormalExit = null;
                }
            } else {
                Logger.error("RecordService", "Recording process exited with error code: " + exitCode);
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

    Process {
        id: niriFocusedOutputProcess

        property var onGetName: null

        running: false
        command: ["niri", "msg", "focused-output"]
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                Logger.error("RecordService", "Failed to get focused output via niri.");
                if (niriFocusedOutputProcess.onGetName) {
                    niriFocusedOutputProcess.onGetName(null);
                    niriFocusedOutputProcess.onGetName = null;
                }
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                if (niriFocusedOutputProcess.onGetName) {
                    const parts = data.split(' ');
                    const name = parts.length > 0 ? parts[parts.length - 1].slice(1)?.slice(0, -1) : null;
                    name ? Logger.log("RecordService", "Focused output is: " + name) : Logger.warn("RecordService", "No focused output found.");
                    niriFocusedOutputProcess.onGetName(name);
                    niriFocusedOutputProcess.onGetName = null;
                }
            }
        }

    }

}
