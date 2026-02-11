import QtQuick
import Quickshell.Io
import qs.Constants
import qs.Modules.Bar.Misc
import qs.Services

MonitorItem {
    property bool _showPercent: false

    symbol: Icons.memory
    fillColor: Colors.green
    critical: SystemStatService.memPercent > 90
    value: Math.round(SystemStatService.memPercent)
    maxValue: 100
    textValue: _showPercent ? SystemStatService.memPercent : SystemStatService.memGb
    textSuffix: _showPercent ? "%" : "GB"
    onClicked: {
        if (action.running) {
            action.signal(15);
            return ;
        }
        action.exec(["wezterm", "start", "--", "btop"]);
    }
    onRightClicked: {
        _showPercent = !_showPercent;
    }

    Process {
        id: action

        running: false
    }

}
