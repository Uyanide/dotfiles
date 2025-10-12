import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
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

        Text {
            text: Icons.download
            font.pointSize: Fonts.icon - 3
            color: Colors.primary
            Layout.leftMargin: 10
        }

        Text {
            text: SystemStatService.formatSpeed(SystemStatService.rxSpeed)
            font.pointSize: Fonts.medium
            font.family: Fonts.primary
            color: Colors.primary
        }

        Item {
            width: 5
        }

        Text {
            text: Icons.upload
            font.pointSize: Fonts.icon - 3
            color: Colors.primary
        }

        Text {
            text: SystemStatService.formatSpeed(SystemStatService.txSpeed)
            font.pointSize: Fonts.medium
            font.family: Fonts.primary
            color: Colors.primary
        }

    }

}
