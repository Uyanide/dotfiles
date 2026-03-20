import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Constants
import qs.Modules.Background
import qs.Services

Variants {
    model: Quickshell.screens

    Item {
        id: root

        property var modelData
        readonly property color tintColor: BackgroundService.tintColor
        readonly property real tintOpacity: BackgroundService.tintOpacity
        readonly property real blurPercentage: BackgroundService.blurPercentage
        readonly property real blurRadius: BackgroundService.blurRadius

        PanelWindow {
            id: bdWindow

            screen: modelData
            WlrLayershell.namespace: "quickshell-backdrop"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            ScrollBackground {
                id: scrollBg

                screen: modelData
            }

        }

    }

}
