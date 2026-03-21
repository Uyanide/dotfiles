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
                anchors.fill: parent
                color: Colors.mSurface
                opacity: BarService.focusMode ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Style.animationSlow
                        easing.type: Easing.InOutCubic
                    }

                }

            }

            Rectangle {
                id: barBackground

                anchors.fill: parent

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.rgba(Colors.mSurface.r, Colors.mSurface.g, Colors.mSurface.b, 0.8)
                    }

                    GradientStop {
                        position: 1
                        color: Qt.rgba(Colors.mSurface.r, Colors.mSurface.g, Colors.mSurface.b, 0)
                    }

                }

            }

            RowLayout {
                id: leftLayout

                height: parent.height - Style.marginXS * 2

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: Style.marginXS
                }

                UIconButton {
                    textOverride: "󰣇"
                    fontFamily: Fonts.nerd
                    baseSize: parent.height - Style.marginXS * 2
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

                height: parent.height - Style.marginXS * 2

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                Time {
                }

            }

            RowLayout {
                id: rightLayout

                height: parent.height - Style.marginXS * 2

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: Style.marginXS
                }

                Connections {
                    function onShowLyricsBarChanged() {
                        if (LyricsService.showLyricsBar) {
                            LyricsService.registerComponent("LyricsBar");
                            SystemStatService.unregisterComponent("BarMonitors");
                        } else {
                            LyricsService.unregisterComponent("LyricsBar");
                            SystemStatService.registerComponent("BarMonitors");
                        }
                    }

                    target: LyricsService
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    RowLayout {
                        id: monitorsLayout

                        anchors.right: parent.right
                        height: parent.height
                        y: LyricsService.showLyricsBar ? Style.barHeight : 0
                        opacity: LyricsService.showLyricsBar ? 0 : 1
                        spacing: Style.marginM
                        Component.onCompleted: {
                            if (!LyricsService.showLyricsBar)
                                SystemStatService.registerComponent("BarMonitors");

                        }
                        Component.onDestruction: {
                            SystemStatService.unregisterComponent("BarMonitors");
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

                        Behavior on y {
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

                    LyricsBar {
                        id: lyricsBar

                        anchors.right: parent.right
                        height: parent.height
                        y: LyricsService.showLyricsBar ? 0 : -Style.barHeight
                        opacity: LyricsService.showLyricsBar ? 1 : 0
                        Component.onCompleted: {
                            if (LyricsService.showLyricsBar)
                                LyricsService.registerComponent("LyricsBar");

                        }
                        Component.onDestruction: {
                            LyricsService.unregisterComponent("LyricsBar");
                        }

                        Behavior on y {
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

                }

                Separator {
                }

                RowLayout {
                    Layout.fillHeight: true
                    spacing: Style.marginS

                    Loader {
                        active: NukeKded6.done

                        sourceComponent: TrayExpander {
                            screen: modelData
                            baseSize: rightLayout.height - Style.marginXS * 2
                        }

                    }

                    UIconButton {
                        iconName: Caffeine.isInhibited ? "mug-off" : "mug"
                        colorFg: Caffeine.isInhibited ? Colors.mOrange : Colors.mYellow
                        baseSize: rightLayout.height - Style.marginXS * 2
                        alwaysHover: Caffeine.isInhibited
                        onClicked: () => {
                            Caffeine.manualToggle();
                        }
                    }

                    UIconButton {
                        iconName: "power"
                        colorFg: Colors.mRed
                        baseSize: rightLayout.height - Style.marginXS * 2
                        onClicked: () => {
                            BarService.toggleRight();
                        }
                    }

                }

            }

        }

    }

}
