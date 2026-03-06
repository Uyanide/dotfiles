import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import qs.Constants
import qs.Components
import qs.Services

ColumnLayout {
    id: root

    property string label: ""
    property string tooltipText: ""
    property var model: {
    }

    Layout.fillWidth: true
    spacing: Style.marginS

    UText {
        text: root.label
        pointSize: Style.fontSizeL
        color: Colors.mPrimary
        font.weight: Style.fontWeightMedium
        Layout.fillWidth: true
        visible: root.model.length > 0
    }

    Repeater {
        id: deviceList

        Layout.fillWidth: true
        model: root.model
        visible: BluetoothService.adapter && BluetoothService.adapter.enabled

        UBox {
            id: device

            readonly property bool canConnect: BluetoothService.canConnect(modelData)
            readonly property bool canDisconnect: BluetoothService.canDisconnect(modelData)
            readonly property bool isBusy: BluetoothService.isDeviceBusy(modelData)

            compact: true

            function getContentColor(defaultColor = Colors.mOnSurface) {
                if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting)
                    return Colors.mPrimary;

                if (modelData.blocked)
                    return Colors.mError;

                return defaultColor;
            }

            Layout.fillWidth: true
            Layout.preferredHeight: deviceLayout.implicitHeight + (Style.marginS * 2)

            RowLayout {
                id: deviceLayout

                anchors.fill: parent
                anchors.margins: Style.marginS
                spacing: Style.marginS
                Layout.alignment: Qt.AlignVCenter

                // One device BT icon
                UIcon {
                    iconName: BluetoothService.getDeviceIcon(modelData)
                    iconSize: Style.fontSizeXXL
                    color: getContentColor(Colors.mOnSurface)
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginXXS

                    // Device name
                    UText {
                        text: modelData.name || modelData.deviceName
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightMedium
                        elide: Text.ElideRight
                        color: getContentColor(Colors.mOnSurface)
                        Layout.fillWidth: true
                    }

                    // Status
                    UText {
                        text: BluetoothService.getStatusString(modelData)
                        visible: text !== ""
                        pointSize: Style.fontSizeXS
                        color: getContentColor(Colors.mOnSurfaceVariant)
                    }

                    // Signal Strength
                    RowLayout {
                        visible: modelData.signalStrength !== undefined
                        Layout.fillWidth: true
                        spacing: Style.marginXS

                        // Device signal strength - "Unknown" when not connected
                        UText {
                            text: BluetoothService.getSignalStrength(modelData)
                            pointSize: Style.fontSizeXS
                            color: getContentColor(Colors.mOnSurfaceVariant)
                        }

                        UIcon {
                            visible: modelData.signalStrength > 0 && !modelData.pairing && !modelData.blocked
                            iconName: BluetoothService.getSignalIcon(modelData)
                            iconSize: Style.fontSizeXS
                            color: getContentColor(Colors.mOnSurface)
                        }

                        UText {
                            visible: modelData.signalStrength > 0 && !modelData.pairing && !modelData.blocked
                            text: (modelData.signalStrength !== undefined && modelData.signalStrength > 0) ? modelData.signalStrength + "%" : ""
                            pointSize: Style.fontSizeXS
                            color: getContentColor(Colors.mOnSurface)
                        }

                    }

                    // Battery
                    UText {
                        visible: modelData.batteryAvailable
                        text: BluetoothService.getBattery(modelData)
                        pointSize: Style.fontSizeXS
                        color: getContentColor(Colors.mOnSurfaceVariant)
                    }

                }

                // Spacer to push connect button to the right
                Item {
                    Layout.fillWidth: true
                }

                // Call to action
                UButton {
                    id: button

                    visible: (modelData.state !== BluetoothDeviceState.Connecting)
                    enabled: (canConnect || canDisconnect) && !isBusy
                    fontSize: Style.fontSizeXS
                    fontWeight: Style.fontWeightMedium
                    backgroundColor: {
                        if (device.canDisconnect && !isBusy)
                            return Colors.mError;

                        return Colors.mPrimary;
                    }
                    text: {
                        if (modelData.pairing)
                            return "Pairing...";

                        if (modelData.blocked)
                            return "Blocked";

                        if (modelData.connected)
                            return "Disconnect";

                        return "Connect";
                    }
                    icon: (isBusy ? "busy" : null)
                    onClicked: {
                        if (modelData.connected)
                            BluetoothService.disconnectDevice(modelData);
                        else
                            BluetoothService.connectDeviceWithTrust(modelData);
                    }
                    onRightClicked: {
                        BluetoothService.forgetDevice(modelData);
                    }
                }

            }

        }

    }

}
