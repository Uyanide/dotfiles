import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Constants
import qs.Services
import qs.Utils

Item {
    id: root

    property int count: 6
    property int barWidth: 5
    property int barSpacing: 3

    implicitWidth: root.barWidth * root.count + root.barSpacing * (root.count - 1)
    implicitHeight: parent.height - 10

    Cava {
        id: cavaProcess

        count: root.count
    }

    RowLayout {
        anchors.fill: parent
        spacing: root.barSpacing

        anchors {
            verticalCenter: parent.verticalCenter
        }

        Repeater {
            model: cavaProcess.values

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
        onClicked: {
            MusicManager.playPause();
        }
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0)
                MusicManager.previous();
            else if (wheel.angleDelta.y < 0)
                MusicManager.next();
        }
    }

}
