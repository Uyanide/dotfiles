import QtQuick
import qs.Constants
import qs.Services

Text {
    text: TimeService.time + " | " + TimeService.dateString
    font.pointSize: Fonts.medium
    font.family: Fonts.primary
    color: Colors.accent
}
