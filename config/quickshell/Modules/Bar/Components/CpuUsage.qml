import QtQuick
import Quickshell.Io
import qs.Constants
import qs.Modules.Bar.Misc
import qs.Services

MonitorItem {
    symbol: Icons.cpu
    fillColor: Colors.teal
    critical: SystemStatService.cpuUsage > 90
    value: Math.round(SystemStatService.cpuUsage)
    maxValue: 100
    textSuffix: "%"
    onClicked: {
        if (action.running) {
            action.signal(15);
            return ;
        }
        action.exec(["ghostty", "-e", "btop"]);
    }

    Process {
        id: action

        running: false
    }

}
