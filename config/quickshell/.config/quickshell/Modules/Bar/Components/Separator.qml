import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Constants

Item {
    id: root

    implicitHeight: Style.barHeight - Style.marginL * 2
    implicitWidth: Style.marginM

    Rectangle {
        anchors.centerIn: parent
        width: 1.5
        height: parent.height
        color: Colors.mOnSurface
    }

}
