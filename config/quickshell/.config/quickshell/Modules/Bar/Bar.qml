import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Components
import qs.Constants
import qs.Modules.Bar.Components
import qs.Modules.Bar.Modules
import qs.Services

Variants {
    model: Quickshell.screens

    Item {
        property var modelData

        PanelWindow {
            id: panel

            screen: modelData
            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayer.Top
            color: Colors.transparent
            implicitHeight: Style.barHeight

            anchors {
                left: true
                right: true
                top: true
            }

            Rectangle {
                id: barBackground

                anchors.fill: parent

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.rgba(Colors.mSurface.r, Colors.mSurface.g, Colors.mSurface.b, BarService.focusMode ? 1 : 0.8)

                        Behavior on color {
                            ColorAnimation {
                                duration: Style.animationSlowest
                                easing.type: Easing.InOutCubic
                            }

                        }

                    }

                    GradientStop {
                        position: 1
                        color: Qt.rgba(Colors.mSurface.r, Colors.mSurface.g, Colors.mSurface.b, BarService.focusMode ? 1 : 0)

                        Behavior on color {
                            ColorAnimation {
                                duration: Style.animationSlowest
                                easing.type: Easing.InOutCubic
                            }

                        }

                    }

                }

            }

            RowLayout {
                id: leftLayout

                height: parent.height - 10

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 5
                }

                UIconButton {
                    textOverride: "󰣇"
                    fontFamily: Fonts.nerd
                    baseSize: parent.height - Style.marginXXS * 2
                    iconSize: Style.fontNerd
                    colorFg: Colors.distro
                    onClicked: () => {
                        BarService.toggleLeft();
                    }
                    onRightClicked: () => {
                        BarService.toggleRight();
                    }
                }

                Separator {
                    implicitWidth: Style.marginXL
                }

                Workspace {
                    screen: modelData
                }

                Separator {
                    implicitWidth: Style.marginXL
                }

                CavaBar {
                }

                Separator {
                    implicitWidth: Style.marginXL
                }

                FocusedWindow {
                }

            }

            RowLayout {
                id: middleLayout

                height: parent.height - 10

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                Time {
                }

            }

            RowLayout {
                id: rightLayout

                height: parent.height - 10

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 5
                }

                Loader {
                    sourceComponent: LyricsService.showLyricsBar ? lyricsComponent : monitorsComponent

                    Component {
                        id: monitorsComponent

                        RowLayout {
                            id: monitorsLayout

                            height: rightLayout.height
                            spacing: Style.marginM
                            Component.onCompleted: {
                                SystemStatService.registerComponent("BarMonitors");
                            }

                            NetworkSpeed {
                            }

                            Separator {
                            }

                            RecordIndicator {
                            }

                            Ip {
                            }

                            CpuTemp {
                            }

                            MemUsage {
                            }

                            CpuUsage {
                            }

                            Battery {
                            }

                            Brightness {
                                screen: modelData
                            }

                            Volume {
                            }

                        }

                    }

                    Component {
                        id: lyricsComponent

                        LyricsBar {
                        }

                    }

                }

                Separator {
                }

                RowLayout {
                    height: rightLayout.height
                    spacing: Style.marginS

                    TrayExpander {
                        screen: modelData
                        baseSize: rightLayout.height - Style.marginXXS * 2
                    }

                    UIconButton {
                        iconName: Caffeine.isInhibited ? "mug-off" : "mug"
                        colorFg: Caffeine.isInhibited ? Colors.mOrange : Colors.mYellow
                        baseSize: rightLayout.height - Style.marginXXS * 2
                        alwaysHover: Caffeine.isInhibited
                        onClicked: () => {
                            Caffeine.manualToggle();
                        }
                    }

                    UIconButton {
                        iconName: "power"
                        colorFg: Colors.mRed
                        baseSize: rightLayout.height - Style.marginXXS * 2
                        onClicked: () => {
                            BarService.toggleRight();
                        }
                    }

                }

            }

        }

    }

}
