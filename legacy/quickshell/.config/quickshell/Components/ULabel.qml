import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Constants

ColumnLayout {
    id: root

    property string label: ""
    property string description: ""
    property string icon: ""
    property color labelColor: Colors.mOnSurface
    property color descriptionColor: Colors.mOnSurfaceVariant
    property color iconColor: Colors.mOnSurface
    property bool showIndicator: false
    property string indicatorTooltip: ""

    opacity: enabled ? 1 : 0.6
    spacing: Style.marginXXS
    visible: root.label != "" || root.description != ""
    Layout.fillWidth: true

    RowLayout {
        spacing: Style.marginXS
        Layout.fillWidth: true
        visible: root.label !== ""

        UIcon {
            visible: root.icon !== ""
            iconName: root.icon
            iconSize: Style.fontSizeXXL
            color: root.iconColor
            Layout.rightMargin: Style.marginS
        }

        UText {
            Layout.fillWidth: !root.showIndicator
            text: root.label
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightSemiBold
            color: labelColor
            wrapMode: Text.WordWrap
        }

    }

    UText {
        visible: root.description !== ""
        Layout.fillWidth: true
        text: root.description
        pointSize: Style.fontSizeS
        color: root.descriptionColor
        wrapMode: Text.WordWrap
        textFormat: Text.StyledText
    }

}
