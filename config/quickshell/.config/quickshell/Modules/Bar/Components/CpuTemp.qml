import QtQuick
import Quickshell.Io
import qs.Constants
import qs.Modules.Bar.Misc
import qs.Services

MonitorItem {
    symbol: SystemStatService.cpuTemp > 80 ? Icons.tempHigh : SystemStatService.cpuTemp > 50 ? Icons.tempMedium : Icons.tempLow
    fillColor: Colors.yellow
    critical: SystemStatService.cpuTemp > 80
    value: Math.round(SystemStatService.cpuTemp)
    maxValue: 100
    textSuffix: "°C"
    onClicked: {
        if (action.running) {
            action.signal(15);
            return ;
        }
        action.exec(["wezterm", "start", "--", "btop"]);
    }

    Process {
        id: action

        running: false
    }

}
