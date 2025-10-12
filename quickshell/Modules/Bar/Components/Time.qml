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
        onClicked: {
            PanelService.getPanel("calendarPanel")?.toggle(this)
        }
    }
}
