import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.Components
import qs.Constants
import qs.Services

UBox {
    id: root

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Style.marginL * 2

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginL

        // Card Header
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                RowLayout {
                    id: content

                    spacing: Style.marginM

                    UImageRounded {
                        width: Style.baseWidgetSize * 2.4
                        height: Style.baseWidgetSize * 2.4
                        imagePath: Quickshell.shellDir + "/Assets/Avatar.jpg"
                        fallbackIcon: "person"
                        radius: Style.radiusL
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginXS

                        UText {
                            Layout.fillWidth: true
                            text: `${HostService.username} @ ${HostService.hostname}`
                            font.weight: Style.fontWeightBold
                            font.pointSize: Style.fontSizeL
                            font.capitalization: Font.Capitalize
                        }

                        UText {
                            text: "Uptime: " + HostService.uptimeText
                            font.pointSize: Style.fontSizeM
                            color: Colors.mOnSurfaceVariant
                        }

                        RowLayout {
                            id: profileLayout

                            spacing: Style.marginXS

                            // Performance
                            UIconButton {
                                iconName: PowerService.getIcon(PowerProfile.Performance)
                                enabled: PowerService.available
                                opacity: enabled ? Style.opacityFull : Style.opacityMedium
                                colorFg: Colors.mRed
                                radius: height / 2
                                alwaysHover: enabled && PowerService.profile === PowerProfile.Performance
                                onClicked: PowerService.setProfile(PowerProfile.Performance)
                            }

                            // Balanced
                            UIconButton {
                                iconName: PowerService.getIcon(PowerProfile.Balanced)
                                enabled: PowerService.available
                                opacity: enabled ? Style.opacityFull : Style.opacityMedium
                                colorFg: Colors.mBlue
                                radius: height / 2
                                alwaysHover: enabled && PowerService.profile === PowerProfile.Balanced
                                onClicked: PowerService.setProfile(PowerProfile.Balanced)
                            }

                            // Eco
                            UIconButton {
                                iconName: PowerService.getIcon(PowerProfile.PowerSaver)
                                enabled: PowerService.available
                                opacity: enabled ? Style.opacityFull : Style.opacityMedium
                                colorFg: Colors.mGreen
                                radius: height / 2
                                alwaysHover: enabled && PowerService.profile === PowerProfile.PowerSaver
                                onClicked: PowerService.setProfile(PowerProfile.PowerSaver)
                            }

                        }

                    }

                    Item {
                        Layout.fillWidth: true
                    }

                }

            }

        }

        UDivider {
            Layout.fillWidth: true
        }

        // Action Tiles
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: Style.marginM
            columnSpacing: Style.marginM

            Repeater {
                model: [{
                    "name": "Lock",
                    "icon": "lock",
                    "isError": false,
                    "clicked": function() {
                        PowerService.lock();
                    }
                }, {
                    "name": "Logout",
                    "icon": "logout",
                    "isError": false,
                    "clicked": function() {
                        PowerService.logout();
                    }
                }, {
                    "name": "Suspend",
                    "icon": "moon",
                    "isError": false,
                    "clicked": function() {
                        PowerService.suspend();
                    }
                }, {
                    "name": "Hibernate",
                    "icon": "bed",
                    "isError": false,
                    "clicked": function() {
                        PowerService.hibernate();
                    }
                }, {
                    "name": "Reboot",
                    "icon": "refresh",
                    "isError": false,
                    "clicked": function() {
                        PowerService.reboot();
                    }
                }, {
                    "name": "Shutdown",
                    "icon": "power",
                    "isError": true,
                    "clicked": function() {
                        PowerService.shutdown();
                    }
                }]

                delegate: Rectangle {
                    id: tile

                    readonly property bool hovered: mouseArea.containsMouse

                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.baseWidgetSize * 2.2
                    radius: Style.radiusL
                    color: hovered ? (modelData.isError ? Colors.mError : Colors.mPrimary) : Colors.mSurface
                    border.color: hovered ? "transparent" : Colors.mOutline
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Style.marginXS

                        UIcon {
                            Layout.alignment: Qt.AlignHCenter
                            iconName: modelData.icon
                            iconSize: Style.fontSizeXL * 1.1
                            color: tile.hovered ? (modelData.isError ? Colors.mOnError : Colors.mOnPrimary) : (modelData.isError ? Colors.mError : Colors.mOnSurface)

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                        UText {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.name
                            pointSize: Style.fontSizeS
                            font.weight: Style.fontWeightMedium
                            color: tile.hovered ? (modelData.isError ? Colors.mOnError : Colors.mOnPrimary) : Colors.mOnSurfaceVariant

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }

                            }

                        }

                    }

                    MouseArea {
                        id: mouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            modelData.clicked();
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

            }

        }

    }

}
