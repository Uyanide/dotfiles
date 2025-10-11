import QtQuick
import Quickshell
import qs.Constants
import qs.Modules.Bar.Misc
import qs.Services

MonitorItem {
    property ShellScreen screen: null

    function getMonitor() {
        return BrightnessService.getMonitorForScreen(screen) || null;
    }

    symbol: Icons.brightness
    fillColor: Colors.blue
    value: {
        const monitor = getMonitor();
        return monitor ? Math.round(monitor.brightness * 100) : "N/A";
    }
    maxValue: 100
    textSuffix: "%"
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
