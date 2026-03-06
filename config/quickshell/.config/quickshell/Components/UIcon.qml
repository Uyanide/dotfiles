import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Constants

Text {
    id: root

    property string iconName: ""
    property string textOverride: ""
    property string fontFamily: Fonts.icon
    property int iconSize: Style.fontSizeL

    color: Colors.mPrimary
    text: textOverride ? textOverride : Icons.get(iconName) || Icons.get(Icons.defaultIcon)
    font.family: fontFamily
    font.pointSize: iconSize
    font.bold: false
}
