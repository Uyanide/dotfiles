import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services

UBox {
    id: root

    readonly property string currentPanel: ShellState.leftSiderbarTab // "bluetooth", "wifi"

    implicitHeight: (root.currentPanel === "bluetooth" ? btContentLoader.implicitHeight : wifiContentLoader.implicitHeight) + toggleGroup.implicitHeight + Style.marginXS * 2 + Style.marginS * 2

    ColumnLayout {
        spacing: Style.marginXS
        anchors.fill: parent
        anchors.margins: Style.marginS

        RowLayout {
            Layout.fillWidth: true

            UDualIconToggle {
                id: toggleGroup

                Layout.preferredWidth: Style.baseWidgetSize * 2.8
                Layout.preferredHeight: Style.baseWidgetSize
                firstOptionValue: "bluetooth"
                firstOptionIcon: "bluetooth"
                secondOptionValue: "wifi"
                secondOptionIcon: "wifi"
                currentValue: root.currentPanel
                onToggled: (value) => {
                    ShellState.leftSiderbarTab = value;
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Item {
                implicitWidth: Math.max(btHeaderLoader.implicitWidth, wfHeaderLoader.implicitWidth)
                implicitHeight: Math.max(btHeaderLoader.implicitHeight, wfHeaderLoader.implicitHeight)

                Loader {
                    id: btHeaderLoader

                    anchors.right: parent.right
                    sourceComponent: bluetoothHeaderComponent
                    opacity: root.currentPanel === "bluetooth" ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                        }

                    }

                }

                Loader {
                    id: wfHeaderLoader

                    anchors.right: parent.right
                    sourceComponent: wifiHeaderComponent
                    opacity: root.currentPanel === "wifi" ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                        }

                    }

                }

                Component {
                    id: bluetoothHeaderComponent

                    RowLayout {
                        UToggle {
                            id: bluetoothSwitch

                            checked: BluetoothService.enabled
                            onToggled: (checked) => {
                                return BluetoothService.setBluetoothEnabled(checked);
                            }
                            baseSize: Style.baseWidgetSize * 0.65
                        }

                        UIconButton {
                            enabled: BluetoothService.enabled
                            iconName: BluetoothService.adapter && BluetoothService.adapter.discovering ? "stop" : "refresh"
                            baseSize: Style.baseWidgetSize * 0.8
                            onClicked: {
                                if (BluetoothService.adapter)
                                    BluetoothService.adapter.discovering = !BluetoothService.adapter.discovering;

                            }
                            colorFg: Colors.mGreen
                        }

                    }

                }

                Component {
                    id: wifiHeaderComponent

                    RowLayout {
                        UToggle {
                            id: wifiSwitch

                            checked: SettingsService.wifiEnabled
                            onToggled: (checked) => {
                                return NetworkService.setWifiEnabled(checked);
                            }
                            baseSize: Style.baseWidgetSize * 0.65
                        }

                        UIconButton {
                            iconName: "refresh"
                            baseSize: Style.baseWidgetSize * 0.8
                            enabled: SettingsService.wifiEnabled && !NetworkService.scanning
                            onClicked: NetworkService.scan()
                            colorFg: Colors.mGreen
                        }

                    }

                }

            }

        }

        UDivider {
            Layout.fillWidth: true
        }

        Item {
            id: contentContainer

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Loader {
                id: btContentLoader

                width: parent.width
                height: parent.height
                x: root.currentPanel === "bluetooth" ? 0 : -width
                opacity: root.currentPanel === "bluetooth" ? 1 : 0
                sourceComponent: bluetoothComponent

                Behavior on x {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Loader {
                id: wifiContentLoader

                width: parent.width
                height: parent.height
                x: root.currentPanel === "wifi" ? 0 : width
                opacity: root.currentPanel === "wifi" ? 1 : 0
                sourceComponent: wifiComponent

                Behavior on x {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Component {
                id: bluetoothComponent

                BluetoothCard {
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                }

            }

            Component {
                id: wifiComponent

                WifiCard {
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                }

            }

        }

    }

}
