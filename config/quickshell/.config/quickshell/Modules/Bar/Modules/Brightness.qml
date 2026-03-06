import QtQuick
import Quickshell
import qs.Components
import qs.Constants
import qs.Services

UProgressExpand {
    property ShellScreen screen: null

    function getMonitor() {
        return BrightnessService.getMonitorForScreen(screen) || null;
    }

    iconName: "sun-filled"
    fillColor: Colors.mBlue
    value: {
        const monitor = getMonitor();
        return monitor ? Math.round(monitor.brightness * 100) : "N/A";
    }
    maxValue: 100
    textSuffix: "%"
    expandOnValueChange: true
    onWheelUp: {
        const monitor = getMonitor();
        if (monitor)
            monitor.increaseBrightness();

    }
    onWheelDown: {
        const monitor = getMonitor();
        if (monitor)
            monitor.decreaseBrightness();

    }
}
