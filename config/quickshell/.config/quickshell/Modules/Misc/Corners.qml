import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Constants
import qs.Modules.Misc
import qs.Services

Scope {
    id: rootScope

    property string namespace: "quickshell-corners"
    property int topMargin: 45
    property int cornerHeight: 20
    property real cornerSize: 1
    property real opacity: BarService.focusMode ? 1 : 0

    Item {
        id: cornersRootItem

        anchors.fill: parent

        Variants {
            model: Quickshell.screens

            Item {
                id: screenItem

                property var modelData
                // property int leftOffset: BarService.leftOffset(modelData)
                // property int rightOffset: BarService.rightOffset(modelData)
                readonly property var leftBar: BarService.getLeftSidebar(modelData.name)
                readonly property var rightBar: BarService.getRightSidebar(modelData.name)
                property int leftOffset: leftBar?.isOpen ? leftBar.barWidth : 0
                property int rightOffset: rightBar?.isOpen ? rightBar.barWidth : 0

                PanelWindow {
                    id: topLeftPanel

                    anchors.top: true
                    anchors.left: true
                    color: "transparent"
                    screen: modelData
                    margins.top: topMargin
                    margins.left: screenItem.leftOffset
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    visible: true
                    WlrLayershell.layer: WlrLayer.Top
                    aboveWindows: false
                    WlrLayershell.namespace: namespace
                    implicitHeight: cornerHeight

                    Corner {
                        id: topLeftCorner

                        position: "bottomleft"
                        size: rootScope.cornerSize
                        offsetX: -32
                        offsetY: 0
                        anchors.top: parent.top
                        opacity: rootScope.opacity
                    }

                }

                PanelWindow {
                    id: topRightPanel

                    anchors.top: true
                    anchors.right: true
                    color: "transparent"
                    screen: modelData
                    margins.top: topMargin
                    margins.right: screenItem.rightOffset
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    visible: true
                    WlrLayershell.layer: WlrLayer.Top
                    aboveWindows: false
                    WlrLayershell.namespace: namespace
                    implicitHeight: cornerHeight

                    Corner {
                        id: topRightCorner

                        position: "bottomright"
                        size: rootScope.cornerSize
                        offsetX: 32
                        offsetY: 0
                        anchors.top: parent.top
                        opacity: rootScope.opacity
                    }

                }

                PanelWindow {
                    id: bottomLeftPanel

                    anchors.bottom: true
                    anchors.left: true
                    color: "transparent"
                    screen: modelData
                    margins.left: screenItem.leftOffset
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    visible: true
                    WlrLayershell.layer: WlrLayer.Top
                    aboveWindows: false
                    WlrLayershell.namespace: namespace
                    implicitHeight: cornerHeight

                    Corner {
                        id: bottomLeftCorner

                        position: "topleft"
                        size: rootScope.cornerSize
                        offsetX: -32
                        offsetY: 0
                        anchors.top: parent.top
                        opacity: rootScope.opacity
                    }

                }

                PanelWindow {
                    id: bottomRightPanel

                    anchors.bottom: true
                    anchors.right: true
                    color: "transparent"
                    screen: modelData
                    margins.right: screenItem.rightOffset
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    visible: true
                    WlrLayershell.layer: WlrLayer.Top
                    aboveWindows: false
                    WlrLayershell.namespace: namespace
                    implicitHeight: cornerHeight

                    Corner {
                        id: bottomRightCorner

                        position: "topright"
                        size: rootScope.cornerSize
                        offsetX: 32
                        offsetY: 0
                        anchors.top: parent.top
                        opacity: rootScope.opacity
                    }

                }

                Behavior on leftOffset {
                    NumberAnimation {
                        duration: Style.animationSlow
                        easing.type: Easing.InOutCubic
                    }

                }

                Behavior on rightOffset {
                    NumberAnimation {
                        duration: Style.animationSlow
                        easing.type: Easing.InOutCubic
                    }

                }

            }

        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Style.animationSlow
            easing.type: Easing.InOutCubic
        }

    }

}
