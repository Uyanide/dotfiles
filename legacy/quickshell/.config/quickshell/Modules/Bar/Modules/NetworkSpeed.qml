import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services

Item {
    implicitHeight: parent.height
    implicitWidth: layout.width + 10

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 5

        UIcon {
            iconName: "arrow-big-down-line-filled"
        }

        Text {
            text: SystemStatService.formatSpeed(SystemStatService.rxSpeed)
            font.pointSize: Style.fontSizeM
            font.family: Fonts.primary
            color: Colors.mPrimary
        }

        Item {
            width: 5
        }

        UIcon {
            iconName: "arrow-big-up-line-filled"
        }

        Text {
            text: SystemStatService.formatSpeed(SystemStatService.txSpeed)
            font.pointSize: Style.fontSizeM
            font.family: Fonts.primary
            color: Colors.mPrimary
        }

    }

}
