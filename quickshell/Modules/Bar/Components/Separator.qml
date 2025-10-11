import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Constants

Item {
    id: root

    implicitHeight: parent.height

    Rectangle {
        anchors.centerIn: parent
        width: 1.5
        height: parent.height * 0.32
        color: Colors.text
    }

}
