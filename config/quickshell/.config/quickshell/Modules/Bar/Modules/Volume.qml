import QtQuick
import Quickshell
import qs.Components
import qs.Constants
import qs.Services

UProgressExpand {
    iconName: AudioService.muted ? "volume-3" : (AudioService.volume >= 0.5 ? "volume" : (AudioService.volume >= 0.2 ? "volume-2" : "volume-2"))
    fillColor: Colors.mLavender
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
        AudioService.setOutputMuted(!AudioService.muted);
    }
    onRightClicked: {
        Quickshell.execDetached(["sh", "-c", "pkill -x -n pwvucontrol || pwvucontrol"]);
    }
}
