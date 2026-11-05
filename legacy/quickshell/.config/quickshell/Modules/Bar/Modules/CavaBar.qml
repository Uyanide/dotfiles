import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Constants
import qs.Modules.Bar.Services
import qs.Services
import qs.Utils

Item {
    id: root

    property int barWidth: 5
    property int barSpacing: 3
    property int mode: 0

    implicitWidth: root.barWidth * CavaBarService.count + root.barSpacing * (CavaBarService.count - 1)
    implicitHeight: Style.barHeight - Style.marginS * 2

    RowLayout {
        anchors.fill: parent
        spacing: root.barSpacing

        anchors {
            verticalCenter: parent.verticalCenter
        }

        Repeater {
            model: mode == 2 ? Array(CavaBarService.count).fill(0.3) : CavaBarService.values

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
            if (mouse.button === Qt.LeftButton) {
                MediaService.playPause();
            } else if (mouse.button === Qt.MiddleButton) {
                mode = (mode + 1) % 3;
                if (mode === 0) {
                    Logger.log("CavaBar", "Cava bar mode set to Auto");
                    CavaBarService.forceEnable = false;
                    CavaBarService.forceDisable = false;
                } else if (mode === 1) {
                    Logger.log("CavaBar", "Cava bar mode set to Always On");
                    CavaBarService.forceEnable = true;
                    CavaBarService.forceDisable = false;
                } else if (mode === 2) {
                    Logger.log("CavaBar", "Cava bar mode set to Always Off");
                    CavaBarService.forceEnable = false;
                    CavaBarService.forceDisable = true;
                }
            } else if (mouse.button === Qt.RightButton) {
                LyricsService.toggleLyricsBar();
            }
        }
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0)
                MediaService.previous();
            else if (wheel.angleDelta.y < 0)
                MediaService.next();
        }
    }

}
