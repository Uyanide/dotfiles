import QtQuick
import qs.Constants
import qs.Modules.Bar.Misc
import qs.Services

MonitorItem {
    symbol: AudioService.muted ? Icons.volumeMuted : (AudioService.volume >= 0.66 ? Icons.volumeHigh : (AudioService.volume >= 0.33 ? Icons.volumeMedium : Icons.volumeLow))
    fillColor: Colors.lavender
    value: Math.round(AudioService.volume * 100)
    maxValue: 100
    textSuffix: "%"
    onWheelUp: {
        AudioService.increaseVolume();
    }
    onWheelDown: {
        AudioService.decreaseVolume();
    }
    onClicked: {
        AudioService.toggleMute();
    }
}
