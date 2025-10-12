import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Services

Item {
    // Text {
    //     id: ipText
    //     anchors.verticalCenter: parent.verticalCenter
    //     text: Icons.global + " " + (showCountryCode ? IpService.countryCode : IpService.ip)
    //     font.pixelSize: Fonts.medium
    //     color: Colors.peach
    // }

    id: root

    property bool showCountryCode: true

    implicitHeight: parent.height
    implicitWidth: layout.width + 10

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        Text {
            text: Icons.global
            font.pointSize: Fonts.icon + 6
            color: Colors.peach
        }

        Item {
            id: expander

            implicitWidth: mouseArea.containsMouse ? ipText.implicitWidth + 10 : 0
            implicitHeight: parent.height
            clip: true

            Text {
                id: ipText

                text: showCountryCode ? IpService.countryCode : IpService.ip
                font.pointSize: showCountryCode ? Fonts.medium : Fonts.small
                font.family: Fonts.primary
                color: Colors.peach
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.InOutCubic
                }

            }

        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                WriteClipboard.write(showCountryCode ? IpService.countryCode : IpService.ip);
                SendNotification.show("Copied to clipboard", showCountryCode ? IpService.countryCode : IpService.ip);
            } else if (mouse.button === Qt.RightButton)
                showCountryCode = !showCountryCode;
            else if (mouse.button === Qt.MiddleButton)
                IpService.refresh();
        }
    }

}
