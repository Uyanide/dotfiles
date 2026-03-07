import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Constants
import qs.Services

Variants {
    model: Quickshell.screens

    Item {
        id: root

        property var modelData
        readonly property color tintColor: BackgroundService.tintColor
        readonly property real tintOpacity: BackgroundService.tintOpacity
        readonly property real blurPercentage: BackgroundService.blurPercentage
        readonly property real blurRadius: BackgroundService.blurRadius

        PanelWindow {
            id: bgWindow

            readonly property bool doBlur: BarService.focusMode && (BackgroundService.previewPath === "")
            readonly property string imagePath: BackgroundService.previewPath || BackgroundService.cachedPath

            screen: modelData
            WlrLayershell.namespace: "quickshell-background"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                anchors.fill: parent
                color: Colors.mSurface

                Item {
                    anchors.fill: parent

                    Item {
                        id: bgManager

                        property string activeSource: bgWindow.imagePath
                        property bool showFirst: true

                        anchors.fill: parent
                        visible: false
                        onActiveSourceChanged: {
                            showFirst = !showFirst;
                            if (showFirst)
                                bgImg1.source = activeSource;
                            else
                                bgImg2.source = activeSource;
                        }
                        Component.onCompleted: {
                            if (showFirst)
                                bgImg1.source = activeSource;
                            else
                                bgImg2.source = activeSource;
                        }

                        Image {
                            id: bgImg1

                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            opacity: (bgManager.showFirst && status === Image.Ready) ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Style.animationSlow
                                }

                            }

                        }

                        Image {
                            id: bgImg2

                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            opacity: (!bgManager.showFirst && status === Image.Ready) ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Style.animationSlow
                                }

                            }

                        }

                    }

                    MultiEffect {
                        source: bgManager
                        anchors.fill: bgManager
                        colorizationColor: root.tintColor
                        colorization: bgWindow.doBlur ? root.tintOpacity : 0
                        blurEnabled: true
                        blur: bgWindow.doBlur ? root.blurPercentage : 0
                        blurMax: root.blurRadius

                        Behavior on blur {
                            NumberAnimation {
                                duration: Style.animationSlow
                            }

                        }

                        Behavior on colorization {
                            NumberAnimation {
                                duration: Style.animationSlow
                            }

                        }

                    }

                }

            }

        }

        PanelWindow {
            id: bdWindow

            property bool doBlur: true
            property string imagePath: BackgroundService.cachedPath

            screen: modelData
            WlrLayershell.namespace: "quickshell-backdrop"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                anchors.fill: parent
                color: Colors.mSurface

                Item {
                    anchors.fill: parent

                    Item {
                        id: backdropManager

                        property string activeSource: bdWindow.imagePath
                        property bool showFirst: true

                        anchors.fill: parent
                        visible: false
                        onActiveSourceChanged: {
                            showFirst = !showFirst;
                            if (showFirst)
                                bdImg1.source = activeSource;
                            else
                                bdImg2.source = activeSource;
                        }
                        Component.onCompleted: {
                            if (showFirst)
                                bdImg1.source = activeSource;
                            else
                                bdImg2.source = activeSource;
                        }

                        Image {
                            id: bdImg1

                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            opacity: (backdropManager.showFirst && status === Image.Ready) ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Style.animationSlow
                                }

                            }

                        }

                        Image {
                            id: bdImg2

                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            opacity: (!backdropManager.showFirst && status === Image.Ready) ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Style.animationSlow
                                }

                            }

                        }

                    }

                    MultiEffect {
                        source: backdropManager
                        anchors.fill: backdropManager
                        colorizationColor: root.tintColor
                        colorization: bdWindow.doBlur ? root.tintOpacity : 0
                        blurEnabled: true
                        blur: bdWindow.doBlur ? root.blurPercentage : 0
                        blurMax: root.blurRadius

                        Behavior on blur {
                            NumberAnimation {
                                duration: Style.animationSlow
                            }

                        }

                        Behavior on colorization {
                            NumberAnimation {
                                duration: Style.animationSlow
                            }

                        }

                    }

                }

            }

        }

    }

}
