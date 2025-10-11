import QtQuick
import Quickshell.Io
import qs.Constants
import qs.Modules.Bar.Misc
import qs.Services

MonitorItem {
    symbol: Icons.memory
    fillColor: Colors.green
    value: Math.round(SystemStatService.memPercent)
    maxValue: 100
    textValue: SystemStatService.memGb
    textSuffix: "G"
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
