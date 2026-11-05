pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int defaultDuration: 2000

    property bool active: false
    property string message: ""
    property string iconName: ""

    function show(message: string, duration: int) {
        root._showInternal("", message, duration);
    }

    function showWithIcon(iconName: string, message: string, duration: int) {
        root._showInternal(iconName, message, duration);
    }

    function _showInternal(iconName: string, message: string, duration: int) {
        root.iconName = iconName;
        root.message = message;
        root.active = true;
        resetTimer.interval = duration > 0 ? duration : root.defaultDuration;
        resetTimer.restart();
    }

    Timer {
        id: resetTimer

        repeat: false
        onTriggered: root.active = false
    }

}
