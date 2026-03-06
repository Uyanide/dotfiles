import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import qs.Constants
import qs.Services
import qs.Components
import qs.Modules.Sidebar.Misc

ColumnLayout {
    spacing: Style.marginM

    Rectangle {
        visible: !(BluetoothService.adapter && BluetoothService.adapter.enabled)
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Colors.transparent

        // Center the content within this rectangle
        ColumnLayout {
            anchors.centerIn: parent
            spacing: Style.marginM

            UIcon {
                iconName: "bluetooth-off"
                iconSize: 64
                color: Colors.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }

            UText {
                text: "Bluetooth is turned off"
                pointSize: Style.fontSizeL
                color: Colors.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }

            UText {
                text: "Enable Bluetooth"
                pointSize: Style.fontSizeS
                color: Colors.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
            }

        }

    }

    UScrollView {
        visible: BluetoothService.adapter && BluetoothService.adapter.enabled
        Layout.fillWidth: true
        Layout.fillHeight: true
        horizontalPolicy: ScrollBar.AlwaysOff
        verticalPolicy: ScrollBar.AsNeeded
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: Style.marginM

            // Connected devices
            BluetoothDevicesList {
                property var items: {
                    if (!BluetoothService.adapter || !Bluetooth.devices)
                        return [];

                    var filtered = Bluetooth.devices.values.filter((dev) => {
                        return dev && !dev.blocked && dev.connected;
                    });
                    return BluetoothService.sortDevices(filtered);
                }

                label: "Connected Devices"
                model: items
                visible: items.length > 0
                Layout.fillWidth: true
            }

            // Known devices
            BluetoothDevicesList {
                property var items: {
                    if (!BluetoothService.adapter || !Bluetooth.devices)
                        return [];

                    var filtered = Bluetooth.devices.values.filter((dev) => {
                        return dev && !dev.blocked && !dev.connected && (dev.paired || dev.trusted);
                    });
                    return BluetoothService.sortDevices(filtered);
                }

                label: "Known Devices"
                model: items
                visible: items.length > 0
                Layout.fillWidth: true
            }

            // Available devices
            BluetoothDevicesList {
                property var items: {
                    if (!BluetoothService.adapter || !Bluetooth.devices)
                        return [];

                    var filtered = Bluetooth.devices.values.filter((dev) => {
                        return dev && !dev.blocked && !dev.paired && !dev.trusted;
                    });
                    return BluetoothService.sortDevices(filtered);
                }

                label: "Available Devices"
                model: items
                visible: items.length > 0
                Layout.fillWidth: true
            }

            // Fallback - No devices, scanning
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Style.marginL

                visible: {
                    if (!BluetoothService.adapter || !BluetoothService.adapter.discovering || !Bluetooth.devices)
                        return false;

                    var availableCount = Bluetooth.devices.values.filter((dev) => {
                        return dev && !dev.paired && !dev.pairing && !dev.blocked && (dev.signalStrength === undefined || dev.signalStrength > 0);
                    }).length;
                    return (availableCount === 0);
                }

                UBusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: true
                    width: Style.fontSizeL
                    height: Style.fontSizeL
                }

                UText {
                    text: "Pairing Mode"
                    pointSize: Style.fontSizeM
                    color: Colors.mOnSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                }

            }

            Item {
                Layout.fillHeight: true
            }

        }

    }

}
