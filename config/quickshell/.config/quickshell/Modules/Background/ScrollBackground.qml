import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Constants
import qs.Services

Item {
    id: root

    required property ShellScreen screen
    readonly property bool doBlur: BarService.focusMode && !BackgroundService.inPreviewMode
    readonly property bool isOverview: Niri.overviewActive
    readonly property real centerCropRatio: 0.9
    readonly property color tintColor: BackgroundService.tintColor
    readonly property real tintOpacity: BackgroundService.tintOpacity
    readonly property real blurPercentage: BackgroundService.blurPercentage
    readonly property real blurRadius: BackgroundService.blurRadius
    property string imagePath: ""
    property bool showFirst: true
    property int outputHeight: 0
    property int workspaceCount: 0
    property int focusedIndex: -1
    readonly property real viewportHeight: outputHeight > 0 ? outputHeight : height
    readonly property real scrollProgress: {
        if (workspaceCount <= 1 || focusedIndex < 0)
            return 0.5;
 // Center
        return Math.max(0, Math.min(1, (focusedIndex - 1) / (workspaceCount - 1)));
    }

    function updateOutput() {
        const outputInfo = Niri.outputCache[screen.name];
        if (!outputInfo)
            return ;

        outputHeight = outputInfo.height;
    }

    function updateWorkspaces() {
        let count = 0;
        for (let i = 0; i < Niri.workspaces.count; i++) {
            const ws = Niri.workspaces.get(i);
            if (ws.output.toLowerCase() === screen.name.toLowerCase())
                count++;

        }
        workspaceCount = count;
        updateFocusedIndex();
    }

    function updateFocusedIndex() {
        const focusedWorkspaceId = Niri.focusedWorkspaceId;
        if (focusedWorkspaceId === -1)
            return ;

        const ws = Niri.workspaceCache[focusedWorkspaceId];
        if (!ws)
            return ;

        if (ws.output.toLowerCase() !== screen.name.toLowerCase())
            return ;

        focusedIndex = ws.idx;
    }

    anchors.fill: parent
    Component.onCompleted: {
        updateOutput();
        updateWorkspaces();
    }

    Connections {
        function updateDisplay() {
            showFirst = !showFirst;
            if (showFirst)
                bgImg1.source = imagePath;
            else
                bgImg2.source = imagePath;
        }

        function onDisplayPathChanged() {
            imagePath = BackgroundService.displayPath;
            Qt.callLater(updateDisplay);
        }

        target: BackgroundService
    }

    Connections {
        function onOutputsChanged() {
            updateOutput();
        }

        function onWorkspaceChanged() {
            updateWorkspaces();
        }

        function onFocusedWorkspaceIdChanged() {
            updateFocusedIndex();
        }

        target: Niri
    }

    Rectangle {
        id: bgContainer

        anchors.fill: parent
        clip: true
        color: Colors.mSurface

        BackgroundImage {
            id: bgImg1

            viewportHeight: root.viewportHeight
            scrollProgress: root.scrollProgress
            isOverview: root.isOverview
            centerCropRatio: root.centerCropRatio
            isActive: root.showFirst
        }

        BackgroundImage {
            id: bgImg2

            viewportHeight: root.viewportHeight
            scrollProgress: root.scrollProgress
            isOverview: root.isOverview
            centerCropRatio: root.centerCropRatio
            isActive: !root.showFirst
        }

    }

    MultiEffect {
        source: bgContainer
        anchors.fill: bgContainer
        colorizationColor: tintColor
        colorization: doBlur ? tintOpacity : 0
        blurEnabled: true
        blur: doBlur ? blurPercentage : 0
        blurMax: blurRadius

        Behavior on blur {
            NumberAnimation {
                duration: Style.animationSlow
                easing.type: Easing.InOutCubic
            }

        }

        Behavior on colorization {
            NumberAnimation {
                duration: Style.animationSlow
                easing.type: Easing.InOutCubic
            }

        }

    }

}
