import QtQuick
import Quickshell
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property int count: 6
    property bool forceEnable: false
    property bool forceDisable: false
    property alias values: cavaProcess.values

    Cava {
        id: cavaProcess

        count: root.count
        forceEnable: root.forceEnable
        forceDisable: root.forceDisable
    }

}
