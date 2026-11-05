import QtQuick
import qs.Constants
import qs.Utils

Image {
    id: root

    required property real viewportHeight
    required property real scrollProgress
    required property bool isOverview
    required property real centerCropRatio
    property bool isActive: true
    readonly property real clampedCenterCropRatio: Math.max(0.01, Math.min(1, centerCropRatio))
    property real imageScale: isOverview ? 1 : 1 / clampedCenterCropRatio
    readonly property real imageSourceWidth: sourceSize.width > 0 ? sourceSize.width : implicitWidth
    readonly property real imageSourceHeight: sourceSize.height > 0 ? sourceSize.height : implicitHeight
    readonly property real imageScaledHeight: {
        if (imageSourceWidth <= 0 || imageSourceHeight <= 0 || width <= 0)
            return 0;

        return Math.max(viewportHeight, width * imageSourceHeight / imageSourceWidth);
    }
    readonly property real effectiveScaledHeight: imageScaledHeight * imageScale
    readonly property real initialYOffset: (imageScale - 1) * imageScaledHeight / 2
    readonly property real maxScrollOffset: Math.max(0, effectiveScaledHeight - viewportHeight)

    fillMode: Image.PreserveAspectCrop
    width: parent.width
    height: imageScaledHeight
    transformOrigin: Item.Center
    scale: imageScale
    y: initialYOffset - maxScrollOffset * scrollProgress

    Connections {
        function onStatusChanged() {
            if (status === Image.Ready && isActive)
                opacity = 1;
            else
                opacity = 0;
        }

        function onIsActiveChanged() {
            deleteTimer.stop();
            if (isActive && status === Image.Ready) {
                opacity = 1;
            } else {
                opacity = 0;
                if (!isActive)
                    deleteTimer.start();

            }
        }

        target: root
    }

    Timer {
        id: deleteTimer

        function onTriggered() {
            root.source = "";
        }

        interval: Style.animationNormal + 100
        running: false
        repeat: false
    }

    Behavior on y {
        NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
        }

    }

}
