import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Components
import qs.Constants

Item {
    id: root

    property alias iconName: icon.iconName
    property alias textOverride: icon.textOverride
    property alias fontFamily: icon.fontFamily
    property int baseSize: Style.fontSizeXXXL
    property alias iconSize: icon.iconSize
    property color colorFg: Colors.mPrimary
    property color colorBg: Colors.transparent
    property color colorFgHover: Colors.mOnPrimary
    property color colorBgHover: colorFg
    readonly property bool hovered: alwaysHover || mouseArea.containsMouse
    property real radius: Style.radiusS
    property bool disabledHover: false
    property bool alwaysHover: false

    signal entered()
    signal exited()
    signal clicked()
    signal rightClicked()
    signal middleClicked()

    implicitWidth: baseSize
    implicitHeight: baseSize

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: !disabledHover
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onEntered: root.entered()
        onExited: root.exited()
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else if (mouse.button === Qt.MiddleButton)
                root.middleClicked();
            else if (mouse.button === Qt.LeftButton)
                root.clicked();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.hovered ? colorBgHover : colorBg
        radius: root.radius

        Behavior on color {
            ColorAnimation {
                duration: Style.animationNormal
                easing.type: Easing.InOutCubic
            }

        }

    }

    UIcon {
        id: icon

        color: root.hovered ? colorFgHover : colorFg
        anchors.centerIn: parent

        Behavior on color {
            ColorAnimation {
                duration: Style.animationNormal
                easing.type: Easing.InOutCubic
            }

        }

    }

}
