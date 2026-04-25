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
    property var windowIndexCache: ({
    })
    property bool hasFocusedWindow: focusedWindowIndex >= 0
    property int focusedWindowIndex: -1
    property int focusedWorkspaceId: -1
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
    property var castCache: ({
    })
    property var castOutputs: []
    property bool isCasting: false

    signal workspaceChanged()
    signal activeWindowChanged()
    signal windowListChanged()
    signal outputsChanged()
    signal castOutputsListChanged()

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
        outputsChanged();
    }

    function _recollectWorkspaces(workspacesData) {
        const workspacesList = [];
        workspaceCache = {
        };
        focusedWorkspaceId = -1;
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
            if (wsData.isFocused) {
                focusedOutput = wsData.output || "";
                focusedWorkspaceId = wsData.id;
            }
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

    function _rebuildWindowIndexCache() {
        const cache = {
        };
        for (var i = 0; i < windows.length; i++) {
            cache[windows[i].id] = i;
        }
        windowIndexCache = cache;
    }

    function _syncFocusedWindowIndex(preferredWindowId) {
        var nextIndex = -1;
        if (preferredWindowId !== undefined && preferredWindowId !== null) {
            const cachedIndex = windowIndexCache[preferredWindowId];
            if (cachedIndex !== undefined)
                nextIndex = cachedIndex;

        }
        if (nextIndex < 0 && focusedWindowIndex >= 0 && focusedWindowIndex < windows.length && windows[focusedWindowIndex].isFocused)
            nextIndex = focusedWindowIndex;

        if (nextIndex < 0)
            nextIndex = windows.findIndex((w) => {
            return w.isFocused;
        });

        const hasChanged = nextIndex !== focusedWindowIndex;
        focusedWindowIndex = nextIndex;
        return hasChanged;
    }

    function recollectWindows(windowsData) {
        const windowsList = [];
        for (const win of windowsData) {
            windowsList.push(getWindowData(win));
        }
        windows = toSortedWindowList(windowsList);
        _rebuildWindowIndexCache();
        const focusedChanged = _syncFocusedWindowIndex();
        windowListChanged();
        if (focusedChanged)
            activeWindowChanged();

    }

    function _handleWindowOpenedOrChanged(eventData) {
        try {
            const windowData = eventData.window;
            const cachedIndex = windowIndexCache[windowData.id];
            const existingIndex = cachedIndex !== undefined ? cachedIndex : -1;
            const newWindow = getWindowData(windowData);
            // Find the previously focused window ID before any modifications
            const previouslyFocusedId = focusedWindowIndex >= 0 && focusedWindowIndex < windows.length ? windows[focusedWindowIndex].id : null;
            if (existingIndex >= 0)
                windows[existingIndex] = newWindow;
            else
                windows.push(newWindow);
            windows = toSortedWindowList(windows);
            _rebuildWindowIndexCache();
            const focusedChanged = _syncFocusedWindowIndex(newWindow.isFocused ? windowData.id : null);
            if (newWindow.isFocused) {
                // Clear focus on the previously focused window by ID (not index, since list was re-sorted)
                if (previouslyFocusedId !== null && previouslyFocusedId !== windowData.id) {
                    const oldFocusedIndex = windowIndexCache[previouslyFocusedId];
                    const oldFocusedWindow = oldFocusedIndex !== undefined ? windows[oldFocusedIndex] : null;
                    if (oldFocusedWindow)
                        oldFocusedWindow.isFocused = false;

                }
                activeWindowChanged();
            } else if (focusedChanged) {
                activeWindowChanged();
            }
            windowListChanged();
        } catch (e) {
            Logger.e("NiriService", "Error handling WindowOpenedOrChanged:", e);
        }
    }

    function _handleWindowClosed(eventData) {
        try {
            const windowId = eventData.id;
            const cachedIndex = windowIndexCache[windowId];
            const windowIndex = cachedIndex !== undefined ? cachedIndex : -1;
            if (windowIndex >= 0) {
                const wasFocused = windows[windowIndex].isFocused;
                windows.splice(windowIndex, 1);
                _rebuildWindowIndexCache();
                if (_syncFocusedWindowIndex() || wasFocused)
                    activeWindowChanged();

                windowListChanged();
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

    function _handleWorkspaceActivated(eventData) {
        try {
            const workspaceId = eventData.id;
            if (workspaceId === focusedWorkspaceId)
                return ;

            // update workspaceCache
            const workspace = workspaceCache[workspaceId];
            if (!workspace) {
                workspaceUpdateTimer.restart();
                return ;
            }
            const focusedOutputName = workspace.output;
            focusedOutput = focusedOutputName || "";
            const oldWorkspace = workspaceCache[focusedWorkspaceId];
            if (oldWorkspace) {
                oldWorkspace.isFocused = false;
                oldWorkspace.isActive = oldWorkspace.output !== focusedOutputName;
            }
            workspace.isFocused = true;
            workspace.isActive = true;
            // update workspaces ListModel
            for (var i = 0; i < workspaces.count; i++) {
                const ws = workspaces.get(i);
                if (ws.id === workspaceId) {
                    workspaces.setProperty(i, "isFocused", true);
                    workspaces.setProperty(i, "isActive", true);
                } else if (ws.id === focusedWorkspaceId) {
                    workspaces.setProperty(i, "isFocused", false);
                    workspaces.setProperty(i, "isActive", ws.output !== focusedOutputName);
                }
            }
            focusedWorkspaceId = workspaceId;
        } catch (e) {
            Logger.e("NiriService", "Error handling WorkspaceActivated:", e);
        }
    }

    function _handleWindowFocusChanged(eventData) {
        try {
            const focusedId = eventData.id;
            const previousFocusedId = focusedWindowIndex >= 0 && focusedWindowIndex < windows.length ? windows[focusedWindowIndex].id : null;
            if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.length)
                windows[focusedWindowIndex].isFocused = false;

            if (focusedId) {
                const cachedIndex = windowIndexCache[focusedId];
                const newIndex = cachedIndex !== undefined ? cachedIndex : -1;
                if (newIndex >= 0 && newIndex < windows.length)
                    windows[newIndex].isFocused = true;

            }
            if (_syncFocusedWindowIndex(focusedId) || previousFocusedId !== focusedId)
                activeWindowChanged();

        } catch (e) {
            Logger.e("NiriService", "Error handling WindowFocusChanged:", e);
        }
    }

    function _handleWindowLayoutsChanged(eventData) {
        try {
            const previousFocusedId = focusedWindowIndex >= 0 && focusedWindowIndex < windows.length ? windows[focusedWindowIndex].id : null;
            var hasMatchedWindow = false;
            for (const change of eventData.changes) {
                const windowId = change[0];
                const layout = change[1];
                const windowIndex = windowIndexCache[windowId];
                const window = windowIndex !== undefined ? windows[windowIndex] : null;
                if (window)
                    window.position = getWindowPosition(layout);

                hasMatchedWindow = hasMatchedWindow || window !== null;
            }
            if (!hasMatchedWindow)
                return ;

            windows = toSortedWindowList(windows);
            _rebuildWindowIndexCache();
            if (_syncFocusedWindowIndex(previousFocusedId))
                activeWindowChanged();

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

    function _syncCasts() {
        isCasting = Object.keys(castCache).length > 0;
        castOutputs = [];
        for (const castId in castCache) {
            const cast = castCache[castId];
            if (cast.output) {
                if (!castOutputs.includes(cast.output))
                    castOutputs.push(cast.output);
            }
        }
        castOutputsListChanged();
    }

    function _handleCastsChanged(eventData) {
        try {
            const casts = eventData.casts || [];
            castCache = {
            };
            castOutputs = [];
            for (const cast of casts) {
                const castData = {
                    "id": cast.stream_id,
                    "stream_id": cast.stream_id,
                    "session_id": cast.session_id,
                    "kind": cast.kind,
                    "output": cast.target?.Output?.name,
                    "pid": cast.pid
                };
                castCache[castData.id] = castData;
            }
            _syncCasts();
        } catch (e) {
            Logger.e("NiriService", "Error handling CastsChanged:", e);
        }
    }

    function _handleCastStopped(eventData) {
        try {
            const castId = eventData.stream_id;
            delete castCache[castId];
            _syncCasts();
        } catch (e) {
            Logger.e("NiriService", "Error handling CastStopped:", e);
        }
    }

    function _handleCastStartedOrChanged(eventData) {
        try {
            const cast = eventData.cast;
            if (!cast)
                return ;
            if (cast.is_active === true) {
                // If the cast is active, we can treat it as a new or updated cast
                const castData = {
                    "id": cast.stream_id,
                    "stream_id": cast.stream_id,
                    "session_id": cast.session_id,
                    "kind": cast.kind,
                    "output": cast.target?.Output?.name,
                    "pid": cast.pid
                };
                castCache[castData.id] = castData;
            } else {
                // If the cast is not active, we should remove it from the cache
                const castId = cast.stream_id;
                delete castCache[castId];
            }
            _syncCasts();
        } catch (e) {
            Logger.e("NiriService", "Error handling CastStartedOrChanged:", e);
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
                        _handleWorkspaceActivated(event.WorkspaceActivated);
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
                    else if (event.CastsChanged)
                        _handleCastsChanged(event.CastsChanged);
                    else if (event.CastStopped)
                        _handleCastStopped(event.CastStopped);
                    else if (event.CastStartedOrChanged)
                        _handleCastStartedOrChanged(event.CastStartedOrChanged);
                } catch (e) {
                    Logger.e("NiriService", "Error parsing event stream:", e, data);
                }
            }
        }

    }

    workspaces: ListModel {
    }

}
