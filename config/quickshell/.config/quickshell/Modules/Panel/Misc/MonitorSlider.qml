import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Noctalia

Item {
    id: root

    property string icon: "volume-high"
    property real value: 50
    property real from: 0
    property real to: 100
    property color colorFill: Colors.primary
    property color colorRest: Colors.surface0

    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: Style.marginS

        NIcon {
            id: iconItem

            icon: root.icon
            color: root.colorFill
        }

        Rectangle {
            id: whole

            Layout.fillWidth: true
            color: root.colorRest
            radius: height / 2
            height: Style.baseWidgetSize * 0.3

            Rectangle {
                id: fill

                width: Math.max(0, Math.min(whole.width, (root.value - root.from) / (root.to - root.from) * whole.width))
                height: parent.height
                color: root.colorFill
                radius: height / 2
                anchors.left: parent.left
            }

        }

    }

}
