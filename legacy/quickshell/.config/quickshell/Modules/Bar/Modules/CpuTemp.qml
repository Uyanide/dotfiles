import QtQuick
import qs.Components
import qs.Constants
import qs.Modules.Bar.Services
import qs.Services

UProgressExpand {
    iconName: "temperature"
    fillColor: Colors.mYellow
    critical: SystemStatService.cpuTemp > 80
    value: Math.round(SystemStatService.cpuTemp)
    maxValue: 100
    textSuffix: "°C"
    onClicked: {
        MonitorProcess.toggle();
    }
}
