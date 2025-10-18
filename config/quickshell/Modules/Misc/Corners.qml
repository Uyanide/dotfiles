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

    property var shell
    property string namespace: "quickshell-corners"
    property int topMargin: 45
    property int cornerHeight: 20
    property real cornerSize: 1
    property real opacity: Niri.noFocus ? 0 : 1

    Item {
        id: cornersRootItem

        anchors.fill: parent

        Variants {
            model: Quickshell.screens

            Item {
                property var modelData

                PanelWindow {
                    id: fakeBar

                    anchors.top: true
                    anchors.left: true
                    anchors.right: true
                    color: "transparent"
                    screen: modelData
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    visible: true
                    WlrLayershell.layer: WlrLayer.Background
                    aboveWindows: false
                    WlrLayershell.namespace: namespace
                    implicitHeight: topMargin

                    Rectangle {
                        anchors.fill: parent
                        color: Colors.base
                        opacity: rootScope.opacity
                    }

                }

                PanelWindow {
                    id: topLeftPanel

                    anchors.top: true
                    anchors.left: true
                    color: "transparent"
                    screen: modelData
                    margins.top: topMargin
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    visible: true
                    WlrLayershell.layer: WlrLayer.Background
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
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    visible: true
                    WlrLayershell.layer: WlrLayer.Background
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
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    visible: true
                    WlrLayershell.layer: WlrLayer.Background
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
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    visible: true
                    WlrLayershell.layer: WlrLayer.Background
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

            }

        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: 1000
            easing.type: Easing.InOutCubic
        }

    }

}
