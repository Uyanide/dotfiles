import QtQuick
import Quickshell.Services.UPower
import qs.Constants
import qs.Modules.Bar.Misc
import qs.Services

MonitorItem {
    readonly property var battery: UPower.displayDevice
    readonly property bool isReady: (battery && battery.ready && battery.isLaptopBattery && battery.isPresent)
    readonly property real percent: (isReady ? (battery.percentage * 100) : 0)
    readonly property bool charging: (isReady ? battery.state === UPowerDeviceState.Charging : false)
    property int lowBatteryThreshold: 20

    symbol: {
        return charging ? Icons.charging : percent >= 80 ? Icons.battery100 : percent >= 60 ? Icons.battery75 : percent >= 40 ? Icons.battery50 : percent >= 20 ? Icons.battery25 : Icons.battery00;
    }
    fillColor: Colors.sapphire
    value: percent
    critical: isReady && !charging && percent <= lowBatteryThreshold
    maxValue: 100
    textSuffix: "%"
    pointerCursor: false
}
