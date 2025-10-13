import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.Constants
import qs.Modules.Bar.Components
import qs.Modules.Bar.Misc
import qs.Modules.Misc
import qs.Services

Scope {
    id: rootScope

    property var shell

    Item {
        id: barRootItem

        anchors.fill: parent

        Variants {
            model: Quickshell.screens

            Item {
                property var modelData

                PanelWindow {
                    id: panel

                    screen: modelData
                    WlrLayershell.namespace: "quickshell-bar"
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
                        color: Niri.noFocus ? null : Colors.base

                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Niri.noFocus ? 0.8 : 1)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Style.animationSlowest
                                        easing.type: Easing.InOutCubic
                                    }

                                }

                            }

                            GradientStop {
                                position: 1
                                color: Qt.rgba(Colors.base.r, Colors.base.g, Colors.base.b, Niri.noFocus ? 0 : 1)

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

                        SymbolButton {
                            symbol: Icons.distro
                            buttonColor: Colors.distroColor
                            onClicked: {
                                PanelService.getPanel("controlCenterPanel")?.toggle(this)
                            }
                            onRightClicked: {
                                if (action.running) {
                                    action.signal(15);
                                    return ;
                                }
                                action.exec(["rofi", "-show", "drun"]);
                            }
                        }

                        Separator {
                        }

                        Workspace {
                            screen: modelData
                        }

                        Separator {
                        }

                        Item {
                            width: 10
                        }

                        CavaBar {
                            count: 6
                        }

                        Item {
                            width: 10
                        }

                        Separator {
                        }

                        Item {
                            width: 10
                        }

                        FocusedWindow {
                            maxWidth: 400
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

                        RowLayout {
                            id: monitorsLayout
                            visible: !SettingsService.showLyricsBar

                            height: parent.height
                            NetworkSpeed {
                            }

                            Separator {
                            }

                            Item {
                                width: 10
                            }

                            Ip {
                                showCountryCode: true
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

                        LyricsBar {
                            id: lyricsBar
                            visible: SettingsService.showLyricsBar
                            width: 600
                        }

                        Item {
                            width: 5
                        }

                        Separator {
                        }

                        Item {
                            width: 5
                        }

                        TrayExpander {
                            screen: modelData
                        }

                        SymbolButton {
                            symbol: Caffeine.isInhibited ? Icons.idleInhibitorActivated : Icons.idleInhibitorDeactivated
                            buttonColor: Caffeine.isInhibited ? Colors.peach : Colors.yellow
                            onClicked: {
                                Caffeine.manualToggle();
                            }

                        }

                        SymbolButton {
                            symbol: Icons.powerMenu
                            buttonColor: Colors.red
                            onClicked: {
                                if (action.running) {
                                    action.signal(15);
                                    return ;
                                }
                                action.exec(["wlogout"]);
                            }
                        }

                    }

                    Process {
                        id: action

                        running: false
                    }

                }

            }

        }

    }

}
