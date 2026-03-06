import QtQuick
import Quickshell.Io
import qs.Components
import qs.Constants
import qs.Modules.Bar.Services
import qs.Services

UProgressExpand {
    // Quickshell.execDetached(["wezterm", "start", "--", "btop"]);

    iconName: "cpu"
    fillColor: Colors.mCyan
    critical: SystemStatService.cpuUsage > 90
    value: Math.round(SystemStatService.cpuUsage)
    maxValue: 100
    textSuffix: "%"
    onClicked: {
        MonitorProcess.toggle();
    }
}
