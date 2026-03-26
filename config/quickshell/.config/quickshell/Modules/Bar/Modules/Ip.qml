import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Services
import qs.Components

UProgressExpand {
    iconName: "world"
    fillColor: Colors.mOrange
    value: 100
    maxValue: 100
    textValue: displayText

    property int displayIndex: 0
    readonly property list<string> displayTexts: [IpService.countryCode, IpService.ip, IpService.alias]
    readonly property string displayText: displayTexts[displayIndex]

    onClicked: (mouse) => {
        WriteClipboard.write(displayText);
        SendNotification.show("Copied to clipboard", displayText, true);
    }

    onRightClicked: {
        let iter = 0;
        do {
            displayIndex = (displayIndex + 1) % displayTexts.length;
        } while (!displayTexts[displayIndex] && iter++ < displayTexts.length);
    }

    onMiddleClicked: {
        IpService.refresh();
    }
}
