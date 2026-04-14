import QtQuick
import Quickshell.Io
import qs.Constants
import qs.Services

Text {
    text: TimeService.time + " | " + TimeService.dateString
    font.pointSize: Style.fontSizeM
    font.family: Fonts.primary
    color: Colors.mPrimary

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            action.running = !action.running;
        }
    }

    Process {
        id: action

        running: false
        command: ["vicinae", "toggle"]
    }

}
