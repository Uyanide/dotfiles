import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Constants
import qs.Services

Variants {
    model: Quickshell.screens

    Item {
        property var modelData

        PanelWindow {
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
                    id: bgManager

                    property string activeSource: BackgroundService.previewPath || (BarService.focusMode ? BackgroundService.cachedBlurredPath : BackgroundService.cachedPath)
                    property bool showFirst: true

                    anchors.fill: parent
                    onActiveSourceChanged: {
                        showFirst = !showFirst;
                        if (showFirst)
                            img1.source = activeSource;
                        else
                            img2.source = activeSource;
                    }
                    Component.onCompleted: {
                        if (showFirst)
                            img1.source = activeSource;
                        else
                            img2.source = activeSource;
                    }

                    Image {
                        id: img1

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
                        id: img2

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

            }

        }

        PanelWindow {
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
                    id: backdropManager

                    property string activeSource: BackgroundService.cachedBlurredPath
                    property bool showFirst: true

                    anchors.fill: parent
                    onActiveSourceChanged: {
                        showFirst = !showFirst;
                        if (showFirst)
                            backImg1.source = activeSource;
                        else
                            backImg2.source = activeSource;
                    }
                    Component.onCompleted: {
                        if (showFirst)
                            backImg1.source = activeSource;
                        else
                            backImg2.source = activeSource;
                    }

                    Image {
                        id: backImg1

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
                        id: backImg2

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

            }

        }

    }

}
