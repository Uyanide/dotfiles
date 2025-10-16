import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Services

Item {
    id: root

    property color fillColor: Colors.red
    property color _actualColor: Colors.red

    visible: RecordService.isRecording
    implicitHeight: parent.height
    implicitWidth: layout.width + 10

    SequentialAnimation {
        id: blinkAnimation

        running: RecordService.isRecording
        loops: Animation.Infinite

        ColorAnimation {
            target: root
            property: "_actualColor"
            to: Qt.rgba(fillColor.r, fillColor.g, fillColor.b, 0)
            duration: Style.animationSlowest
            easing.type: Easing.InOutCubic
        }

        ColorAnimation {
            target: root
            property: "_actualColor"
            to: fillColor
            duration: Style.animationSlowest
            easing.type: Easing.InOutCubic
        }

    }

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        Text {
            text: Icons.record
            font.pointSize: Fonts.icon + 6
            color: _actualColor
        }

        Item {
            id: expander

            implicitWidth: mouseArea.containsMouse ? ipText.implicitWidth + 10 : 0
            implicitHeight: parent.height
            clip: true

            Text {
                id: ipText

                text: RecordService.recordingDisplay
                font.pointSize: Fonts.medium
                font.family: Fonts.primary
                color: fillColor
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.InOutCubic
                }

            }

        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                RecordService.startOrStop();

        }
    }

    Behavior on _actualColor {
        ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.InOutCubic
        }

    }

}
