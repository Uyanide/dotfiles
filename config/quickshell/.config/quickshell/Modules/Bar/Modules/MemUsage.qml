import QtQuick
import qs.Components
import qs.Constants
import qs.Modules.Bar.Services
import qs.Services

UProgressExpand {
    property bool _showPercent: false

    iconName: "database"
    fillColor: Colors.mGreen
    critical: SystemStatService.memPercent > 90
    value: Math.round(SystemStatService.memPercent)
    maxValue: 100
    textValue: _showPercent ? SystemStatService.memPercent : SystemStatService.memGb
    textSuffix: _showPercent ? "%" : "GB"
    onClicked: {
        MonitorProcess.toggle();
    }
    onRightClicked: {
        _showPercent = !_showPercent;
    }
}
