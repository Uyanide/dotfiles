import QtQuick
import qs.Constants
import qs.Services

Text {
    text: TimeService.time + " | " + TimeService.dateString
    font.pointSize: Fonts.medium
    font.family: Fonts.primary
    color: Colors.primary

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                PanelService.getPanel("calendarPanel")?.toggle(this)
            else if (mouse.button === Qt.RightButton)
                PanelService.getPanel("notificationHistoryPanel")?.toggle(this)
        }
    }
}
