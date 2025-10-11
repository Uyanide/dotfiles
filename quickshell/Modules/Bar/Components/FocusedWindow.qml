import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import qs.Constants
import qs.Services

Item {
    id: root

    property real maxWidth: 250
    property string fallbackIcon: "application-x-executable"

    function getAppIcon() {
        try {
            const focusedWindow = Niri.getFocusedWindow();
            if (focusedWindow && focusedWindow.appId) {
                try {
                    const idValue = focusedWindow.appId;
                    const normalizedId = (typeof idValue === 'string') ? idValue : String(idValue);
                    const iconResult = ThemeIcons.iconForAppId(normalizedId.toLowerCase());
                    if (iconResult && iconResult !== "")
                        return iconResult;

                } catch (iconError) {
                    console.warn("Error getting icon from CompositorService:", iconError);
                }
            }
            return ThemeIcons.iconFromName(root.fallbackIcon);
        } catch (e) {
            console.warn("Error in getAppIcon:", e);
            return ThemeIcons.iconFromName(root.fallbackIcon);
        }
    }

    implicitHeight: parent.height

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: 10
        visible: Niri.focusedWindowId !== -1

        Item {
            // Layout.alignment: Qt.AlignVCenter

            id: iconContainer

            implicitWidth: 18
            implicitHeight: 18

            IconImage {
                id: windowIcon

                anchors.fill: parent
                source: getAppIcon()
                asynchronous: true
                smooth: true
                visible: source !== ""
            }

        }

        Item {
            id: titleContainer

            implicitWidth: root.maxWidth
            implicitHeight: parent.height
            // Layout.alignment: Qt.AlignVCenter
            clip: true

            Text {
                id: windowTitle

                text: Niri.focusedWindowTitle
                anchors.verticalCenter: parent.verticalCenter
                font.pointSize: Fonts.medium
                font.family: Fonts.primary
                color: Colors.accent

                Process {
                    id: action

                    running: false
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onEntered: {
                        if (windowTitle.implicitWidth > titleContainer.width)
                            windowTitle.x = titleContainer.width - windowTitle.implicitWidth;

                    }
                    onExited: {
                        windowTitle.x = 0;
                    }
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.MiddleButton) {
                            action.command = ["niri", "msg", "action", "close-window"];
                            action.startDetached();
                        } else if (mouse.button === Qt.LeftButton) {
                            action.command = ["niri", "msg", "action", "center-window"];
                            action.startDetached();
                        }
                    }
                    onWheel: function(wheel) {
                        if (wheel.angleDelta.y > 0) {
                            action.command = ["niri", "msg", "action", "set-column-width", "+10%"];
                            action.startDetached();
                        } else if (wheel.angleDelta.y < 0) {
                            action.command = ["niri", "msg", "action", "set-column-width", "-10%"];
                            action.startDetached();
                        } else if (wheel.angleDelta.x > 0) {
                            action.command = ["niri", "msg", "action", "focus-column-left"];
                            action.startDetached();
                        } else if (wheel.angleDelta.x < 0) {
                            action.command = ["niri", "msg", "action", "focus-column-right"];
                            action.startDetached();
                        }
                    }
                }

                Behavior on x {
                    NumberAnimation {
                        duration: 1000
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }

}
