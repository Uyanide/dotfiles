import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Constants

Item {
    id: root

    required property string symbol
    property color buttonColor: Colors.distroColor
    readonly property alias hovered: mouseArea.containsMouse
    property real iconSize: Fonts.icon
    property real radius: Style.radiusS

    signal clicked()
    signal rightClicked()

    implicitHeight: parent.height
    implicitWidth: parent.height

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else if (mouse.button === Qt.LeftButton)
                root.clicked();
        }
    }

    Text {
        anchors.fill: parent
        text: symbol
        font.family: Fonts.nerd
        font.pointSize: iconSize
        font.bold: false
        color: buttonColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        anchors.fill: parent
        color: parent.hovered ? buttonColor : Colors.transparent
        opacity: 0.3
        radius: root.radius

        Behavior on color {
            ColorAnimation {
                duration: Style.animationNormal
                easing.type: Easing.InOutCubic
            }

        }

    }

}
