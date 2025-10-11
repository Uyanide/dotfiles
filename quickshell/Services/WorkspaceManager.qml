pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    property ListModel workspaces

    workspaces: ListModel {
    }

    function initNiri() {
        updateNiriWorkspaces();
    }

    function updateNiriWorkspaces() {
        const niriWorkspaces = Niri.workspaces || [];
        workspaces.clear();
        for (let i = 0; i < niriWorkspaces.length; i++) {
            const ws = niriWorkspaces[i];
            workspaces.append({
                "id": ws.id,
                "idx": ws.idx || 1,
                "name": ws.name || "",
                "output": ws.output || "",
                "isFocused": ws.isFocused === true,
                "isActive": ws.isActive === true,
                "isUrgent": ws.isUrgent === true
            });
        }
        workspacesChanged();
    }

    function switchToWorkspace(workspaceId) {
            try {
                Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", workspaceId.toString()]);
            } catch (e) {
                console.error("Error switching Niri workspace:", e);
            }
    }

    Connections {
        function onWorkspacesChanged() {
            updateNiriWorkspaces();
        }

        target: Niri
    }

}
