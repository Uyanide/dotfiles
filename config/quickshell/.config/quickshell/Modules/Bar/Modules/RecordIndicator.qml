import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services

Item {
    id: root

    property color fillColor: Colors.mRed
    property color _actualColor: Colors.mRed
    property bool _expand: mouseArea.containsMouse

    visible: RecordService.isRecording
    implicitHeight: Math.max(symbolIcon.implicitHeight, textLabel.implicitHeight)
    implicitWidth: height + expander.implicitWidth

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

        UIcon {
            id: symbolIcon

            iconName: "capture-filled"
            iconSize: Style.fontSizeM + 12
            color: root._actualColor
            Layout.preferredWidth: parent.height
            Layout.preferredHeight: parent.height
        }

        Item {
            id: expander

            implicitHeight: parent.height
            implicitWidth: root._expand ? textLabel.implicitWidth + 10 : 0
            clip: true

            UText {
                id: textLabel

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                text: RecordService.recordingDisplay || "Recording"
                color: root.fillColor
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Style.animationNormal
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
