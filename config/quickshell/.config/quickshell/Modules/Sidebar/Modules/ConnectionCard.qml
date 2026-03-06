import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services

UBox {
    id: root

    property string currentPanel: "bluetooth" // "bluetooth", "wifi"

    implicitHeight: contentLoader.implicitHeight + toggleGroup.implicitHeight + Style.marginXS * 2 + Style.marginS * 2

    ColumnLayout {
        spacing: Style.marginXS
        anchors.fill: parent
        anchors.margins: Style.marginS

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                id: toggleGroup

                Layout.preferredWidth: Style.baseWidgetSize * 2.8
                Layout.preferredHeight: Style.baseWidgetSize
                radius: Math.min(Style.radiusS, height / 2)
                color: Colors.mSurface
                // border.color: Colors.mOutline

                Row {
                    anchors.fill: parent
                    spacing: Style.marginS / 2

                    Rectangle {
                        id: btnBluetooth

                        width: root.currentPanel === "bluetooth" ? (parent.width - parent.spacing) * 0.65 : (parent.width - parent.spacing) * 0.35
                        height: parent.height
                        radius: Math.min(Style.radiusS, height / 2)
                        color: root.currentPanel === "bluetooth" ? Colors.mPrimary : "transparent"

                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }

                        UIcon {
                            anchors.centerIn: parent
                            iconName: "bluetooth"
                            iconSize: Style.fontSizeL
                            color: root.currentPanel === "bluetooth" ? Colors.mOnPrimary : Colors.mOnSurface

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentPanel = "bluetooth"
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Rectangle {
                        id: btnWifi

                        width: root.currentPanel === "wifi" ? (parent.width - parent.spacing) * 0.65 : (parent.width - parent.spacing) * 0.35
                        height: parent.height
                        radius: Math.min(Style.radiusS, height / 2)
                        color: root.currentPanel === "wifi" ? Colors.mPrimary : "transparent"

                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }

                        UIcon {
                            anchors.centerIn: parent
                            iconName: "wifi"
                            iconSize: Style.fontSizeL
                            color: root.currentPanel === "wifi" ? Colors.mOnPrimary : Colors.mOnSurface

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentPanel = "wifi"
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Loader {
                sourceComponent: currentPanel === "bluetooth" ? bluetoothHeaderComponent : wifiHeaderComponent

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

        Loader {
            id: contentLoader

            Layout.fillWidth: true
            Layout.fillHeight: true

            sourceComponent: currentPanel === "bluetooth" ? bluetoothComponent : wifiComponent

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
