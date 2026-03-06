import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Components
import qs.Constants
import qs.Services
import qs.Utils

Item {
    id: root

    property real maxWidth: 320
    property string fallbackIcon: "application-x-executable"

    function getAppIcon(appId) {
        try {
            if (appId) {
                try {
                    const normalizedId = (typeof appId === 'string') ? appId : String(appId);
                    const iconResult = ThemeIcons.iconForAppId(normalizedId.toLowerCase());
                    if (iconResult && iconResult !== "")
                        return iconResult;

                } catch (iconError) {
                    Logger.w("FocusedWindow", "Error getting icon from CompositorService: " + iconError);
                }
            }
            return ThemeIcons.iconFromName(root.fallbackIcon);
        } catch (e) {
            Logger.w("FocusedWindow", "Error in getAppIcon:", e);
            return ThemeIcons.iconFromName(root.fallbackIcon);
        }
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: Math.max(windowIcon.implicitHeight, windowTitle.implicitHeight)

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: 10
        visible: Niri.hasFocusedWindow

        Item {
            // Layout.alignment: Qt.AlignVCenter

            id: iconContainer

            implicitWidth: 18
            implicitHeight: 18

            IconImage {
                id: windowIcon

                anchors.fill: parent
                source: getAppIcon(Niri.focusedWindowAppId)
                asynchronous: true
                smooth: true
                visible: source !== ""
            }

        }

        Item {
            id: titleContainer

            property bool shouldScroll: windowTitle.implicitWidth > width
            property int scrollSpacing: 30

            implicitWidth: root.maxWidth
            implicitHeight: parent.height
            // Layout.alignment: Qt.AlignVCenter
            clip: true

            Item {
                id: scrollContent

                height: parent.height
                anchors.verticalCenter: parent.verticalCenter

                UText {
                    id: windowTitle

                    text: Niri.focusedWindowTitle
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colors.mPrimary
                }

                UText {
                    text: Niri.focusedWindowTitle
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: windowTitle.right
                    anchors.leftMargin: titleContainer.scrollSpacing
                    color: Colors.mPrimary
                    visible: titleContainer.shouldScroll
                }

                NumberAnimation {
                    target: scrollContent
                    property: "x"
                    from: 0
                    to: -(windowTitle.width + titleContainer.scrollSpacing)
                    duration: (windowTitle.width + titleContainer.scrollSpacing) * 10
                    loops: Animation.Infinite
                    running: titleContainer.shouldScroll && mouseArea.containsMouse
                    onRunningChanged: {
                        if (!running)
                            scrollContent.x = 0;

                    }
                }

            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: function(mouse) {
                    if (mouse.button === Qt.MiddleButton)
                        Quickshell.execDetached(["niri", "msg", "action", "close-window"]);
                    else if (mouse.button === Qt.LeftButton)
                        Quickshell.execDetached(["niri", "msg", "action", "center-window"]);
                    else if (mouse.button === Qt.RightButton)
                        Quickshell.execDetached(["niri", "msg", "action", "maximize-window-to-edges"]);
                }
                onWheel: function(wheel) {
                    if (wheel.angleDelta.y > 0)
                        Quickshell.execDetached(["niri", "msg", "action", "set-column-width", "+10%"]);
                    else if (wheel.angleDelta.y < 0)
                        Quickshell.execDetached(["niri", "msg", "action", "set-column-width", "-10%"]);
                    else if (wheel.angleDelta.x > 0)
                        Quickshell.execDetached(["niri", "msg", "action", "focus-column-left"]);
                    else if (wheel.angleDelta.x < 0)
                        Quickshell.execDetached(["niri", "msg", "action", "focus-column-right"]);
                }
            }

        }

    }

}
