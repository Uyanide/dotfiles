import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Services

Item {
    id: root

    property int displayIndex: 0
    readonly property list<string> displayTexts: [IpService.countryCode, IpService.ip, IpService.alias]
    readonly property string displayText: displayTexts[displayIndex]

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

                text: displayText
                font.pointSize: displayIndex === 0 ? Fonts.medium : Fonts.small
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
                WriteClipboard.write(displayText);
                SendNotification.show("Copied to clipboard", displayText);
            } else if (mouse.button === Qt.RightButton){
                let iter = 0;
                do {
                    displayIndex = (displayIndex + 1) % displayTexts.length;
                } while (!displayTexts[displayIndex] && iter++ < displayTexts.length);
            } else if (mouse.button === Qt.MiddleButton)
                IpService.refresh();
        }
    }

}
