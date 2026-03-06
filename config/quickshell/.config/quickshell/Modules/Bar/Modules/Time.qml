import QtQuick
import qs.Constants
import qs.Services

Text {
    text: TimeService.time + " | " + TimeService.dateString
    font.pointSize: Style.fontSizeM
    font.family: Fonts.primary
    color: Colors.mPrimary
}
