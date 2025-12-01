import QtQuick
import Quickshell
import qs.Utils
pragma Singleton

Singleton {
    id: root

    property int count: 6
    property int forceEnable: 6
    property alias values: cavaProcess.values

    Cava {
        id: cavaProcess

        count: root.count
        forceEnable: root.forceEnable
    }

}
