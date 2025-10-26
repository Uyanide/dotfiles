import QtQuick
import Quickshell
import qs.Constants
import qs.Modules.Bar.Misc
import qs.Services

MonitorItem {
    symbol: AudioService.muted ? Icons.volumeMuted : (AudioService.volume >= 0.5 ? Icons.volumeHigh : (AudioService.volume >= 0.2 ? Icons.volumeMedium : Icons.volumeLow))
    fillColor: Colors.lavender
    value: Math.round(AudioService.volume * 100)
    maxValue: 100
    textSuffix: "%"
    expandOnValueChange: true
    onWheelUp: {
        AudioService.increaseVolume();
    }
    onWheelDown: {
        AudioService.decreaseVolume();
    }
    onClicked: {
        AudioService.toggleMute();
    }
    onRightClicked: {
        Quickshell.execDetached(["sh", "-c", "pkill -x -n pwvucontrol || pwvucontrol"]);
    }
}
