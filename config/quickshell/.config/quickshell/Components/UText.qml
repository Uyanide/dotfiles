import QtQuick
import QtQuick.Layouts
import qs.Constants

Text {
    id: root

    property string family: Fonts.primary
    property real pointSize: Style.fontSizeM

    font.family: root.family
    font.weight: Style.fontWeightMedium
    font.pointSize: root.pointSize
    color: Colors.mOnSurface
    elide: Text.ElideRight
    wrapMode: Text.NoWrap
    verticalAlignment: Text.AlignVCenter
}
