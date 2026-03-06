import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Modules.Bar.Components

Item {
    id: root

    property ShellScreen screen
    property int baseSize: Style.baseWidgetSize

    implicitWidth: baseSize + trayContainer.implicitWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        UIconButton {
            iconName: "layout-sidebar-right-expand-filled"
            colorFg: Colors.mGreen
            baseSize: root.baseSize
            disabledHover: true
        }

        Item {
            id: trayContainer

            implicitHeight: parent.height
            implicitWidth: mouseArea.containsMouse ? expandedTray.implicitWidth : 0
            clip: true

            SystemTray {
                id: expandedTray

                screen: root.screen
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Style.animationNormal
                    easing.type: Easing.InOutCubic
                }

            }

        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

}
