import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Constants
import qs.Modules.Bar.Misc

Item {
    id: root

    property int barWidth: 5
    property int barSpacing: 3

    implicitWidth: root.barWidth * CavaBarService.count + root.barSpacing * (CavaBarService.count - 1)
    implicitHeight: parent.height - 10

    RowLayout {
        anchors.fill: parent
        spacing: root.barSpacing

        anchors {
            verticalCenter: parent.verticalCenter
        }

        Repeater {
            model: CavaBarService.values

            Rectangle {
                width: root.barWidth
                implicitHeight: Math.max(1, modelData * (parent.height - 10))
                color: Colors.cavaList[Math.min(Math.floor(modelData * (Colors.cavaList.length - 1)), Colors.cavaList.length - 1)]

                Behavior on height {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutCubic
                    }

                }

            }

        }

    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                MusicManager.playPause();
            else if (mouse.button === Qt.RightButton)
                SettingsService.showLyricsBar = !SettingsService.showLyricsBar;
            else if (mouse.button === Qt.MiddleButton)
                CavaBarService.forceEnable = !CavaBarService.forceEnable;
        }
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0)
                MusicManager.previous();
            else if (wheel.angleDelta.y < 0)
                MusicManager.next();
        }
    }

}
