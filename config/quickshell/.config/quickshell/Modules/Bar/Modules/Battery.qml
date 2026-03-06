import QtQuick
import Quickshell.Services.UPower
import qs.Components
import qs.Constants

UProgressExpand {
    readonly property var battery: UPower.displayDevice
    readonly property bool isReady: (battery && battery.ready && battery.isLaptopBattery && battery.isPresent)
    readonly property real percent: (isReady ? (battery.percentage * 100) : 0)
    readonly property bool charging: (isReady ? battery.state === UPowerDeviceState.Charging : false)
    property int lowBatteryThreshold: 20

    iconName: {
        return charging ? "battery-charging" : percent >= 80 ? "battery-4" : percent >= 60 ? "battery-3" : percent >= 40 ? "battery-2" : percent >= 20 ? "battery-1" : "battery-0";
    }
    fillColor: Colors.mSky
    value: percent
    critical: isReady && !charging && percent <= lowBatteryThreshold
    maxValue: 100
    textSuffix: "%"
    pointerCursor: false
}
