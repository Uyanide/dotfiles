import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Components
import qs.Constants
import qs.Services

Item {
    id: root

    readonly property int switchDistance: Style.barHeight
    readonly property int animationDuration: Style.animationNormal

    implicitWidth: Math.max(timeLayer.implicitWidth, notiLayer.implicitWidth)
    implicitHeight: Math.max(timeLayer.implicitHeight, notiLayer.implicitHeight)
    clip: true

    UText {
        id: timeLayer

        readonly property real restY: (root.height - implicitHeight) / 2

        anchors.horizontalCenter: parent.horizontalCenter
        y: TempNotificationService.active ? restY + root.switchDistance : restY
        opacity: TempNotificationService.active ? 0 : 1
        text: TimeService.time + " | " + TimeService.dateString
        color: Colors.mPrimary

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                action.running = !action.running;
            }
        }

        Process {
            id: action

            running: false
            command: ["vicinae", "toggle"]
        }

        Behavior on y {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }

        }

    }

    RowLayout {
        id: notiLayer

        readonly property real restY: (root.height - implicitHeight) / 2

        anchors.horizontalCenter: parent.horizontalCenter
        y: TempNotificationService.active ? restY : restY - root.switchDistance
        opacity: TempNotificationService.active ? 1 : 0
        spacing: Style.marginXS

        UIcon {
            visible: TempNotificationService.iconName !== ""
            iconName: TempNotificationService.iconName
            color: Colors.mPrimary
        }

        UText {
            text: TempNotificationService.message
            color: Colors.mPrimary
        }

        Behavior on y {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.OutCubic
            }

        }

    }

}
