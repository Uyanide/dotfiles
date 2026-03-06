import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property int floatingWindowPosition: Number.MAX_SAFE_INTEGER
    property ListModel workspaces
    property var windows: []
    property bool hasFocusedWindow: focusedWindowIndex >= 0 && focusedWindowIndex < windows.length
    property int focusedWindowIndex: -1
    property string focusedWindowAppId: hasFocusedWindow ? windows[focusedWindowIndex].appId : ""
    property string focusedWindowTitle: hasFocusedWindow ? windows[focusedWindowIndex].title : ""
    property string focusedOutput: ""
    property ShellScreen focusedScreen: {
        if (!focusedOutput)
            return null;

        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === focusedOutput)
                return Quickshell.screens[i];

        }
        return null;
    }
    property bool overviewActive: false
    property var outputCache: ({
    })
    property var workspaceCache: ({
    })

    signal workspaceChanged()
    signal activeWindowChanged()
    signal windowListChanged()
    signal displayScalesChanged()

    function initialize() {
        niriEventStream.connected = true;
        niriCommandSocket.connected = true;
        startEventStream();
        updateOutputs();
        updateWorkspaces();
        updateWindows();
        _queryDisplayScales();
        Logger.i("NiriService", "Service started");
    }

    // command from https://yalter.github.io/niri/niri_ipc/enum.Request.html
    function sendSocketCommand(sock, command) {
        sock.write(JSON.stringify(command) + "\n");
        sock.flush();
    }

    function startEventStream() {
        sendSocketCommand(niriEventStream, "EventStream");
    }

    function updateOutputs() {
        sendSocketCommand(niriCommandSocket, "Outputs");
    }

    function updateWorkspaces() {
        sendSocketCommand(niriCommandSocket, "Workspaces");
    }

    function updateWindows() {
        sendSocketCommand(niriCommandSocket, "Windows");
    }

    function _queryDisplayScales() {
        sendSocketCommand(niriCommandSocket, "Outputs");
    }

    function recollectOutputs(outputsData) {
        const scales = {
        };
        outputCache = {
        };
        for (const outputName in outputsData) {
            const output = outputsData[outputName];
            if (output && output.name) {
                const isConnected = output.logical !== null && output.current_mode !== null;
                const logical = output.logical || {
                };
                const currentModeIdx = output.current_mode ?? 0;
                const modes = output.modes || [];
                const currentMode = modes[currentModeIdx] || {
                };
                const outputData = {
                    "name": output.name,
                    "connected": isConnected,
                    "scale": logical.scale || 1,
                    "width": logical.width || 0,
                    "height": logical.height || 0,
                    "x": logical.x || 0,
                    "y": logical.y || 0,
                    "physical_width": (output.physical_size && output.physical_size[0]) || 0,
                    "physical_height": (output.physical_size && output.physical_size[1]) || 0,
                    "refresh_rate": currentMode.refresh_rate || 0,
                    "vrr_supported": output.vrr_supported || false,
                    "vrr_enabled": output.vrr_enabled || false,
                    "transform": logical.transform || "Normal"
                };
                outputCache[output.name] = outputData;
                scales[output.name] = outputData;
            }
        }
    }

    function _recollectWorkspaces(workspacesData) {
        const workspacesList = [];
        workspaceCache = {
        };
        for (const ws of workspacesData) {
            const wsData = {
                "id": ws.id,
                "idx": ws.idx,
                "name": ws.name || "",
                "output": ws.output || "",
                "isFocused": ws.is_focused === true,
                "isActive": ws.is_active === true,
                "isUrgent": ws.is_urgent === true,
                "isOccupied": ws.active_window_id ? true : false
            };
            workspacesList.push(wsData);
            workspaceCache[ws.id] = wsData;
            if (wsData.isFocused)
                focusedOutput = wsData.output || "";

        }
        workspacesList.sort((a, b) => {
            if (a.output !== b.output)
                return a.output.localeCompare(b.output);

            return a.idx - b.idx;
        });
        workspaces.clear();
        for (var i = 0; i < workspacesList.length; i++) {
            workspaces.append(workspacesList[i]);
        }
        workspaceChanged();
    }

    function getWindowPosition(layout) {
        if (layout.pos_in_scrolling_layout)
            return {
            "x": layout.pos_in_scrolling_layout[0],
            "y": layout.pos_in_scrolling_layout[1]
        };
        else
            return {
            "x": floatingWindowPosition,
            "y": floatingWindowPosition
        };
    }

    function getWindowOutput(win) {
        for (var i = 0; i < workspaces.count; i++) {
            if (workspaces.get(i).id === win.workspace_id)
                return workspaces.get(i).output;

        }
        return null;
    }

    function getWindowData(win) {
        return {
            "id": win.id,
            "title": win.title || "",
            "appId": win.app_id || "",
            "workspaceId": win.workspace_id || -1,
            "isFocused": win.is_focused === true,
            "output": getWindowOutput(win) || "",
            "position": getWindowPosition(win.layout)
        };
    }

    function toSortedWindowList(windowList) {
        return windowList.map((win) => {
            const workspace = workspaceCache[win.workspaceId];
            const output = (workspace && workspace.output) ? outputCache[workspace.output] : null;
            return {
                "window": win,
                "workspaceIdx": workspace ? workspace.idx : 0,
                "outputX": output ? output.x : 0,
                "outputY": output ? output.y : 0
            };
        }).sort((a, b) => {
            // Sort by output position first
            if (a.outputX !== b.outputX)
                return a.outputX - b.outputX;

            if (a.outputY !== b.outputY)
                return a.outputY - b.outputY;

            // Then by workspace index
            if (a.workspaceIdx !== b.workspaceIdx)
                return a.workspaceIdx - b.workspaceIdx;

            // Then by window position
            if (a.window.position.x !== b.window.position.x)
                return a.window.position.x - b.window.position.x;

            if (a.window.position.y !== b.window.position.y)
                return a.window.position.y - b.window.position.y;

            // Finally by window ID to ensure consistent ordering
            return a.window.id - b.window.id;
        }).map((info) => {
            return info.window;
        });
    }

    function recollectWindows(windowsData) {
        const windowsList = [];
        for (const win of windowsData) {
            windowsList.push(getWindowData(win));
        }
        windows = toSortedWindowList(windowsList);
        windowListChanged();
        // Find focused window index in the SORTED windows array
        focusedWindowIndex = -1;
        for (var i = 0; i < windows.length; i++) {
            if (windows[i].isFocused) {
                focusedWindowIndex = i;
                break;
            }
        }
        activeWindowChanged();
    }

    function _handleWindowOpenedOrChanged(eventData) {
        try {
            const windowData = eventData.window;
            const existingIndex = windows.findIndex((w) => {
                return w.id === windowData.id;
            });
            const newWindow = getWindowData(windowData);
            // Find the previously focused window ID before any modifications
            const previouslyFocusedId = focusedWindowIndex >= 0 && focusedWindowIndex < windows.length ? windows[focusedWindowIndex].id : null;
            if (existingIndex >= 0)
                windows[existingIndex] = newWindow;
            else
                windows.push(newWindow);
            windows = toSortedWindowList(windows);
            if (newWindow.isFocused) {
                focusedWindowIndex = windows.findIndex((w) => {
                    return w.id === windowData.id;
                });
                // Clear focus on the previously focused window by ID (not index, since list was re-sorted)
                if (previouslyFocusedId !== null && previouslyFocusedId !== windowData.id) {
                    const oldFocusedWindow = windows.find((w) => {
                        return w.id === previouslyFocusedId;
                    });
                    if (oldFocusedWindow)
                        oldFocusedWindow.isFocused = false;

                }
                activeWindowChanged();
            }
            windowListChanged();
            workspaceUpdateTimer.restart();
        } catch (e) {
            Logger.e("NiriService", "Error handling WindowOpenedOrChanged:", e);
        }
    }

    function _handleWindowClosed(eventData) {
        try {
            const windowId = eventData.id;
            const windowIndex = windows.findIndex((w) => {
                return w.id === windowId;
            });
            if (windowIndex >= 0) {
                if (windowIndex === focusedWindowIndex) {
                    focusedWindowIndex = -1;
                    activeWindowChanged();
                } else if (focusedWindowIndex > windowIndex) {
                    focusedWindowIndex--;
                }
                windows.splice(windowIndex, 1);
                windowListChanged();
                workspaceUpdateTimer.restart();
            }
        } catch (e) {
            Logger.e("NiriService", "Error handling WindowClosed:", e);
        }
    }

    function _handleWindowsChanged(eventData) {
        try {
            const windowsData = eventData.windows;
            recollectWindows(windowsData);
        } catch (e) {
            Logger.e("NiriService", "Error handling WindowsChanged:", e);
        }
    }

    function _handleWindowFocusChanged(eventData) {
        try {
            const focusedId = eventData.id;
            if (windows[focusedWindowIndex])
                windows[focusedWindowIndex].isFocused = false;

            if (focusedId) {
                const newIndex = windows.findIndex((w) => {
                    return w.id === focusedId;
                });
                if (newIndex >= 0 && newIndex < windows.length)
                    windows[newIndex].isFocused = true;

                focusedWindowIndex = newIndex >= 0 ? newIndex : -1;
            } else {
                focusedWindowIndex = -1;
            }
            activeWindowChanged();
        } catch (e) {
            Logger.e("NiriService", "Error handling WindowFocusChanged:", e);
        }
    }

    function _handleWindowLayoutsChanged(eventData) {
        try {
            for (const change of eventData.changes) {
                const windowId = change[0];
                const layout = change[1];
                const window = windows.find((w) => {
                    return w.id === windowId;
                });
                if (window)
                    window.position = getWindowPosition(layout);

            }
            windows = toSortedWindowList(windows);
            windowListChanged();
        } catch (e) {
            Logger.e("NiriService", "Error handling WindowLayoutChanged:", e);
        }
    }

    function _handleOverviewOpenedOrClosed(eventData) {
        try {
            overviewActive = eventData.is_open;
        } catch (e) {
            Logger.e("NiriService", "Error handling OverviewOpenedOrClosed:", e);
        }
    }

    function _handleScreenshotCaptured(eventData) {
        try {
            const filePath = eventData.path;
            if (filePath)
                Quickshell.execDetached(["screenshot-script", "edit", filePath]);

        } catch (e) {
            Logger.e("NiriService", "Error handling ScreenshotCaptured:", e);
        }
    }

    function switchToWorkspace(workspace) {
        try {
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", workspace.idx.toString()]);
        } catch (e) {
            Logger.e("NiriService", "Failed to switch workspace:", e);
        }
    }

    function scrollWorkspaceContent(direction) {
        try {
            var action = direction < 0 ? "focus-column-left" : "focus-column-right";
            Quickshell.execDetached(["niri", "msg", "action", action]);
        } catch (e) {
            Logger.e("NiriService", "Failed to scroll workspace content:", e);
        }
    }

    function focusWindow(window) {
        try {
            Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", window.id.toString()]);
        } catch (e) {
            Logger.e("NiriService", "Failed to switch window:", e);
        }
    }

    function closeWindow(window) {
        try {
            Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", window.id.toString()]);
        } catch (e) {
            Logger.e("NiriService", "Failed to close window:", e);
        }
    }

    function turnOffMonitors() {
        try {
            Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
        } catch (e) {
            Logger.e("NiriService", "Failed to turn off monitors:", e);
        }
    }

    function turnOnMonitors() {
        try {
            Quickshell.execDetached(["niri", "msg", "action", "power-on-monitors"]);
        } catch (e) {
            Logger.e("NiriService", "Failed to turn on monitors:", e);
        }
    }

    function logout() {
        try {
            Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]);
        } catch (e) {
            Logger.e("NiriService", "Failed to logout:", e);
        }
    }

    function getFocusedScreen() {
        // On niri the code below only works when you have an actual app selected on that screen.
        return null;
    }

    function spawn(command) {
        try {
            const niriCommand = ["niri", "msg", "action", "spawn", "--"].concat(command);
            Logger.d("NiriService", "Calling niri spawn: " + niriCommand.join(" "));
            Quickshell.execDetached(niriCommand);
        } catch (e) {
            Logger.e("NiriService", "Failed to spawn command:", e);
        }
    }

    Component.onCompleted: initialize()

    Timer {
        id: workspaceUpdateTimer

        interval: 50
        repeat: false
        onTriggered: updateWorkspaces()
    }

    Socket {
        id: niriCommandSocket

        path: Quickshell.env("NIRI_SOCKET")
        connected: false

        parser: SplitParser {
            onRead: function(line) {
                try {
                    const data = JSON.parse(line);
                    if (data && data.Ok) {
                        const res = data.Ok;
                        if (res.Windows)
                            recollectWindows(res.Windows);
                        else if (res.Outputs)
                            recollectOutputs(res.Outputs);
                        else if (res.Workspaces)
                            _recollectWorkspaces(res.Workspaces);
                    } else {
                        Logger.e("NiriService", "Niri returned an error:", data.Err, line);
                    }
                } catch (e) {
                    Logger.e("NiriService", "Failed to parse data from socket:", e, line);
                    return ;
                }
            }
        }

    }

    Socket {
        id: niriEventStream

        path: Quickshell.env("NIRI_SOCKET")
        connected: false

        parser: SplitParser {
            onRead: (data) => {
                try {
                    const event = JSON.parse(data.trim());
                    if (event.WorkspacesChanged)
                        _recollectWorkspaces(event.WorkspacesChanged.workspaces);
                    else if (event.WindowOpenedOrChanged)
                        _handleWindowOpenedOrChanged(event.WindowOpenedOrChanged);
                    else if (event.WindowClosed)
                        _handleWindowClosed(event.WindowClosed);
                    else if (event.WindowsChanged)
                        _handleWindowsChanged(event.WindowsChanged);
                    else if (event.WorkspaceActivated)
                        workspaceUpdateTimer.restart();
                    else if (event.WindowFocusChanged)
                        _handleWindowFocusChanged(event.WindowFocusChanged);
                    else if (event.WindowLayoutsChanged)
                        _handleWindowLayoutsChanged(event.WindowLayoutsChanged);
                    else if (event.OverviewOpenedOrClosed)
                        _handleOverviewOpenedOrClosed(event.OverviewOpenedOrClosed);
                    else if (event.OutputsChanged)
                        _queryDisplayScales();
                    else if (event.ConfigLoaded)
                        _queryDisplayScales();
                    else if (event.ScreenshotCaptured)
                        _handleScreenshotCaptured(event.ScreenshotCaptured);
                } catch (e) {
                    Logger.e("NiriService", "Error parsing event stream:", e, data);
                }
            }
        }

    }

    workspaces: ListModel {
    }

}
