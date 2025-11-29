import QtQuick
import Quickshell
import Quickshell.Io
import qs.Utils
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property var workspaces: []
    property var windows: {}
    property int focusedWindowId: -1
    property bool noFocus: focusedWindowId === -1
    property bool inOverview: false
    property string focusedWindowTitle: ""
    property string focusedWindowAppId: ""
    property var onScreenshotCaptured: null

    function updateFocusedWindowTitle() {
        if (windows && windows[focusedWindowId]) {
            focusedWindowTitle = windows[focusedWindowId].title || "";
            focusedWindowAppId = windows[focusedWindowId].appId || "";
        } else {
            focusedWindowTitle = "";
            focusedWindowAppId = "";
        }
    }

    function getFocusedWindow() {
        return (windows && windows[focusedWindowId]) || null;
    }

    Component.onCompleted: {
        eventStream.running = true;
    }

    Process {
        id: workspaceProcess

        running: false
        command: ["niri", "msg", "--json", "workspaces"]

        stdout: SplitParser {
            onRead: function(line) {
                try {
                    const workspacesData = JSON.parse(line);
                    const workspacesList = [];
                    for (const ws of workspacesData) {
                        workspacesList.push({
                            "id": ws.id,
                            "idx": ws.idx,
                            "name": ws.name || "",
                            "output": ws.output || "",
                            "isFocused": ws.is_focused === true,
                            "isActive": ws.is_active === true,
                            "isUrgent": ws.is_urgent === true,
                            "activeWindowId": ws.active_window_id
                        });
                    }
                    workspacesList.sort((a, b) => {
                        if (a.output !== b.output)
                            return a.output.localeCompare(b.output);

                        return a.id - b.id;
                    });
                    root.workspaces = workspacesList;
                } catch (e) {
                    Logger.error("Niri", "Failed to parse workspaces:", e, line);
                }
            }
        }

    }

    Process {
        id: eventStream

        running: false
        command: ["niri", "msg", "--json", "event-stream"]

        stdout: SplitParser {
            onRead: (data) => {
                try {
                    const event = JSON.parse(data.trim());
                    if (event.WorkspacesChanged) {
                        workspaceProcess.running = true;
                    }
                    if (event.WindowsChanged) {
                        try {
                            const windowsData = event.WindowsChanged.windows;
                            const windowsMap = {};
                            for (const win of windowsData) {
                                if (win.is_focused === true) {
                                    root.focusedWindowId = win.id;
                                }
                                windowsMap[win.id] = {
                                    "title": win.title || "",
                                    "appId": win.app_id || "",
                                    "workspaceId": win.workspace_id || null,
                                    "isFocused": win.is_focused === true
                                };
                            }
                            root.windows = windowsMap;
                            root.updateFocusedWindowTitle();
                        } catch (e) {
                            Logger.error("Niri", "Error parsing windows event:", e);
                        }
                    }
                    if (event.WorkspaceActivated) {
                        workspaceProcess.running = true;
                    }
                    if (event.WindowFocusChanged) {
                        try {
                            const focusedId = event.WindowFocusChanged.id;
                            if (focusedId) {
                                if (root.windows[focusedId]) {
                                    root.focusedWindowId = focusedId;
                                } else {
                                    root.focusedWindowId = -1;
                                }

                            } else {
                                root.focusedWindowId = -1;
                            }
                            root.updateFocusedWindowTitle();
                        } catch (e) {
                            Logger.error("Niri", "Error parsing window focus event:", e);
                        }
                    }
                    if (event.OverviewOpenedOrClosed) {
                        try {
                            root.inOverview = event.OverviewOpenedOrClosed.is_open === true;
                        } catch (e) {
                            Logger.error("Niri", "Error parsing overview state:", e);
                        }
                    }
                    if (event.WindowOpenedOrChanged) {
                        try {
                            const targetWin = event.WindowOpenedOrChanged.window;
                            const id = targetWin.id;
                            const isFocused = targetWin.is_focused === true;
                            let needUpdateTitle = false;
                            if (id) {
                                if (root.windows && root.windows[id]) {
                                    const win = root.windows[id];
                                    // Update existing window
                                    needUpdateTitle = win.title !== targetWin.title;
                                    win.title = targetWin.title || win.title;
                                    win.appId = targetWin.app_id || win.appId;
                                    win.workspaceId = targetWin.workspace_id || win.workspaceId;
                                    win.isFocused = isFocused;
                                } else {
                                    // New window
                                    const newWin = {
                                        "title": targetWin.title || "",
                                        "appId": targetWin.app_id || "",
                                        "workspaceId": targetWin.workspace_id || null,
                                        "isFocused": isFocused
                                    };
                                    root.windows[id] = targetWin;
                                }
                                if (isFocused) {
                                    if (root.focusedWindowId !== id || needUpdateTitle){
                                        root.focusedWindowId = id;
                                        root.updateFocusedWindowTitle();
                                    }
                                }

                            }
                        } catch (e) {
                            Logger.error("Niri", "Error parsing window opened/changed event:", e);
                        }
                    }
                    if (event.windowClosed) {
                        try {
                            const closedId = event.windowClosed.id;
                            if (closedId && (root.windows && root.windows[closedId])) {
                                delete root.windows[closedId];
                                if (root.focusedWindowId === closedId) {
                                    root.focusedWindowId = -1;
                                    root.updateFocusedWindowTitle();
                                }
                            }
                        } catch (e) {
                            Logger.error("Niri", "Error parsing window closed event:", e);
                        }
                    }
                    if (event.ScreenshotCaptured) {
                        try {
                            const path = event.ScreenshotCaptured.path || "";
                            if (!path) return;
                            if (root.onScreenshotCaptured && typeof root.onScreenshotCaptured === "function") {
                                root.onScreenshotCaptured(path);
                            }
                        } catch (e) {
                            Logger.error("Niri", "Error parsing screenshot captured event:", e);
                        }
                    }
                } catch (e) {
                    Logger.error("Niri", "Error parsing event stream:", e, data);
                }
            }
        }

    }

}
