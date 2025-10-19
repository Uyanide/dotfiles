import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Modules.Bar.Misc

Item {
    id: root

    property ShellScreen screen

    implicitHeight: parent.height
    implicitWidth: layout.implicitWidth

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        SymbolButton {
            symbol: Icons.tray
            buttonColor: Colors.green
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
                    duration: 200
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
