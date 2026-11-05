import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services

Item {
    id: root

    required property ShellScreen screen
    property ListModel localWorkspaces
    property real masterProgress: 0
    property bool effectsActive: false
    property color effectColor: Colors.mPrimary
    property int horizontalPadding: 16
    property int spacingBetweenPills: 8

    function triggerUnifiedWave() {
        effectColor = Colors.mPrimary;
        masterAnimation.restart();
    }

    function syncWorkspaces() {
        let j = 0;
        let focusChanged = false;
        for (let i = 0; i < Niri.workspaces.count; i++) {
            const ws = Niri.workspaces.get(i);
            if (ws.output.toLowerCase() === screen.name.toLowerCase()) {
                if (j < localWorkspaces.count) {
                    const existing = localWorkspaces.get(j);
                    if (ws.isFocused && !existing.isFocused)
                        focusChanged = true;

                    localWorkspaces.setProperty(j, "id", ws.id);
                    localWorkspaces.setProperty(j, "idx", ws.idx);
                    localWorkspaces.setProperty(j, "isFocused", ws.isFocused);
                    localWorkspaces.setProperty(j, "isActive", ws.isActive);
                    localWorkspaces.setProperty(j, "isUrgent", ws.isUrgent);
                    localWorkspaces.setProperty(j, "isOccupied", ws.isOccupied);
                } else {
                    localWorkspaces.append(ws);
                    if (ws.isFocused)
                        focusChanged = true;

                }
                j++;
            }
        }
        while (localWorkspaces.count > j)localWorkspaces.remove(localWorkspaces.count - 1)
        if (focusChanged)
            triggerUnifiedWave();

    }

    function syncWorkspaceFocus() {
        for (let i = 0; i < localWorkspaces.count; i++) {
            const ws = localWorkspaces.get(i);
            const wsData = Niri.workspaceCache[ws.id];
            if (!wsData) {
                localWorkspaces.setProperty(i, "isFocused", false);
                localWorkspaces.setProperty(i, "isActive", false);
            } else {
                localWorkspaces.setProperty(i, "isFocused", wsData.isFocused);
                localWorkspaces.setProperty(i, "isActive", wsData.isActive);
            }
        }
    }

    implicitWidth: pillRow.implicitWidth + horizontalPadding * 2
    Component.onCompleted: syncWorkspaces()

    Connections {
        function onWorkspaceChanged() {
            syncWorkspaces();
        }

        function onFocusedWorkspaceIdChanged() {
            syncWorkspaceFocus();
        }

        target: Niri
    }

    SequentialAnimation {
        id: masterAnimation

        PropertyAction {
            target: root
            property: "effectsActive"
            value: true
        }

        NumberAnimation {
            target: root
            property: "masterProgress"
            from: 0
            to: 1
            duration: 1000
            easing.type: Easing.OutQuint
        }

        PropertyAction {
            target: root
            property: "effectsActive"
            value: false
        }

        PropertyAction {
            target: root
            property: "masterProgress"
            value: 0
        }

    }

    Row {
        id: pillRow

        spacing: spacingBetweenPills
        anchors.centerIn: parent

        Repeater {
            id: workspaceRepeater

            model: localWorkspaces

            Item {
                id: workspacePillContainer

                height: 12
                width: {
                    if (model.isFocused)
                        return 44;
                    else if (model.isActive)
                        return 28;
                    else
                        return 16;
                }

                Rectangle {
                    // half of focused height (if you want to animate this too)

                    id: workspacePill

                    anchors.fill: parent
                    radius: height / 2
                    color: {
                        if (model.isFocused)
                            return Colors.mPrimary;

                        if (model.isActive)
                            return Colors.mOnSurfaceVariant;

                        if (model.isUrgent)
                            return Theme.error;

                        return Colors.mSurfaceVariant;
                    }
                    scale: model.isFocused ? 1 : 0.9
                    z: 0

                    MouseArea {
                        id: pillMouseArea

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Niri.switchToWorkspace(model);
                        }
                        z: 20
                        hoverEnabled: true
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }

                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.InOutCubic
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutCubic
                        }

                    }

                }

                Rectangle {
                    id: pillBurst

                    anchors.centerIn: workspacePillContainer
                    width: workspacePillContainer.width + 18 * root.masterProgress
                    height: workspacePillContainer.height + 18 * root.masterProgress
                    radius: height / 2
                    color: root.effectColor
                    border.color: root.effectColor
                    border.width: 2 + 6 * (1 - root.masterProgress)
                    opacity: root.effectsActive && model.isFocused ? (1 - root.masterProgress) * 0.7 : 0
                    visible: root.effectsActive && model.isFocused
                    z: 1
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }

                }

                Behavior on height {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

    }

    localWorkspaces: ListModel {
    }

}
