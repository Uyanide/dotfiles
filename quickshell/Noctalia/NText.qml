import QtQuick
import QtQuick.Layouts
import qs.Constants
import qs.Noctalia

Text {
    id: root

    property string family: Fonts.primary
    property real pointSize: Style.fontSizeM
    property real fontScale: 1

    font.family: root.family
    font.weight: Style.fontWeightMedium
    font.pointSize: root.pointSize * fontScale
    color: Color.mOnSurface
    elide: Text.ElideRight
    wrapMode: Text.NoWrap
    verticalAlignment: Text.AlignVCenter
}
