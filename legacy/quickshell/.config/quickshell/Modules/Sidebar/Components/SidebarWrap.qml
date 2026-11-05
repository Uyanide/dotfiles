import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Constants
import qs.Modules.Misc
import qs.Modules.Sidebar
import qs.Services

PanelWindow {
    id: root

    property int barWidth: Style.sidebarWidth
    property int realWidth: 0
    property bool isOpen: false
    property Component contentComponent: null
    property bool isLeft: true

    function open() {
        realWidth = barWidth;
        isOpen = true;
    }

    function close() {
        realWidth = 0;
        isOpen = false;
    }

    Component.onCompleted: {
        if (root.isLeft)
            BarService.registerLeft(modelData.name, root);
        else
            BarService.registerRight(modelData.name, root);
    }
    screen: modelData
    WlrLayershell.namespace: root.isLeft ? "quickshell-sidebar-left" : "quickshell-sidebar-right"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    implicitWidth: realWidth > 0 ? barWidth : 0 // jump change for better performance (maybe)
    visible: realWidth > 0
    margins.top: Style.barHeight
    color: Colors.transparent

    anchors {
        left: isLeft
        top: true
        bottom: true
        right: !isLeft
    }

    Rectangle {
        id: sidebarContent

        width: root.barWidth
        height: parent.height
        x: isLeft ? root.realWidth - root.barWidth : root.barWidth - root.realWidth
        color: Colors.mSurface

        Loader {
            anchors.fill: parent
            active: root.realWidth > 0
            asynchronous: true
            sourceComponent: root.contentComponent
        }

    }

    mask: Region {
        item: sidebarContent
    }

    Behavior on realWidth {
        NumberAnimation {
            duration: Style.animationSlow
            easing.type: Easing.InOutCubic
        }

    }

}
