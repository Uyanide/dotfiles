import QtQuick
import Quickshell.Io
import qs.Constants
import qs.Modules.Bar.Misc
import qs.Services

MonitorItem {
    symbol: Icons.cpuTemp > 80 ? Icons.tempHigh : Icons.cpuTemp > 50 ? Icons.tempMedium : Icons.tempLow
    fillColor: Icons.cpuTemp > 80 ? Colors.red : Colors.yellow
    value: Math.round(SystemStatService.cpuTemp)
    maxValue: 120
    textSuffix: "°C"
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
