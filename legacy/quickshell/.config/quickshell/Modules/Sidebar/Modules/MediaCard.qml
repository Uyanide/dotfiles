import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services
import qs.Utils

UBox {
    id: root

    implicitHeight: 200

    // Track whether we have an active media player
    readonly property bool hasActivePlayer: MediaService.currentPlayer && MediaService.canPlay

    // Wrapper - rounded rect clipper
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true

        // Solid color background (always present as base layer)
        Rectangle {
            anchors.fill: parent
            color: Colors.mSurface
        }

        // Background image that covers everything
        Image {
            id: bgImage

            readonly property int dim: 256

            anchors.fill: parent
            visible: source.toString() !== ""
            source: MediaService.trackArtUrl
            sourceSize: Qt.size(dim, dim)
            fillMode: Image.PreserveAspectCrop
            layer.enabled: true
            layer.smooth: true

            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 8
                blur: 0.33
            }

        }

        // Dark overlay for readability
        Rectangle {
            anchors.fill: parent
            color: Colors.mSurface
            opacity: 0.65
            radius: Style.radiusM
        }

        // Background visualizer on top of the artwork
        Item {
            id: visualizerContainer

            anchors.fill: parent
            layer.enabled: true

            Item {
                anchors.fill: parent

                Cava {
                    id: cava

                    count: 32
                }

                Repeater {
                    model: cava.values

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: (parent.width - (cava.count - 1) * Style.marginXS) / cava.count
                        height: modelData * parent.height
                        x: index * (width + Style.marginXS)
                        color: Colors.mPrimary
                        radius: width / 2
                        opacity: 0.25
                    }

                }

            }

            layer.effect: MultiEffect {
                maskEnabled: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 0

                maskSource: ShaderEffectSource {

                    sourceItem: Rectangle {
                        width: root.width
                        height: root.height
                        radius: Style.radiusM
                        color: "white"
                    }

                }

            }

        }

        layer.effect: MultiEffect {
            maskEnabled: true
            maskThresholdMin: 0.95
            maskSpreadAtMin: 0.15

            maskSource: ShaderEffectSource {

                sourceItem: Rectangle {
                    width: root.width
                    height: root.height
                    radius: Style.radiusM
                    color: "white"
                }

            }

        }

    }

    // Player selector
    Rectangle {
        id: playerSelectorButton

        property var currentPlayer: MediaService.getAvailablePlayers()[MediaService.selectedPlayerIndex]

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Style.marginXS
        anchors.leftMargin: Style.marginM
        anchors.rightMargin: Style.marginM
        height: Style.baseWidgetSize
        visible: MediaService.getAvailablePlayers().length > 1
        radius: Style.radiusM
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: Style.marginS

            UIcon {
                iconName: "caret-down"
                iconSize: Style.fontSizeXXL
                color: Colors.mOnSurfaceVariant
            }

            UText {
                text: playerSelectorButton.currentPlayer ? playerSelectorButton.currentPlayer.identity : ""
                pointSize: Style.fontSizeXS
                color: Colors.mOnSurfaceVariant
                Layout.fillWidth: true
            }

        }

        MouseArea {
            id: playerSelectorMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                var menuItems = [];
                var players = MediaService.getAvailablePlayers();
                for (var i = 0; i < players.length; i++) {
                    menuItems.push({
                        "label": players[i].identity,
                        "action": i.toString(),
                        "icon": "disc",
                        "enabled": true,
                        "visible": true
                    });
                }
                playerContextMenu.model = menuItems;
                playerContextMenu.openAtItem(playerSelectorButton, 0, playerSelectorButton.height);
            }
        }

        UContextMenu {
            id: playerContextMenu

            parent: root
            width: 200
            verticalPolicy: ScrollBar.AlwaysOff
            onTriggered: function(action) {
                var index = parseInt(action);
                if (!isNaN(index))
                    MediaService.switchToPlayer(index);

            }
        }

    }

    // Content container that adjusts for player selector
    Item {
        anchors.fill: parent
        anchors.topMargin: playerSelectorButton.visible ? (playerSelectorButton.height + Style.marginXS + Style.marginM) : Style.marginM
        anchors.leftMargin: Style.marginM
        anchors.rightMargin: Style.marginM
        anchors.bottomMargin: Style.marginM

        Item {
            id: fallback
            visible: !root.hasActivePlayer
            anchors.fill: parent

            Item {
                anchors.centerIn: parent
                implicitWidth: Style.fontSizeXXXL * 4
                implicitHeight: Style.fontSizeXXXL * 4

                // Pulsating audio circles (background)
                Repeater {
                    model: 3

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * (1 + index * 0.2)
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.color: Colors.mOnSurfaceVariant
                        border.width: 2
                        opacity: 0

                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite

                            PauseAnimation {
                                duration: index * 600
                            }

                            NumberAnimation {
                                from: 1
                                to: 0
                                duration: 2000
                                easing.type: Easing.OutQuad
                            }

                        }

                        SequentialAnimation on scale {
                            running: true
                            loops: Animation.Infinite

                            PauseAnimation {
                                duration: index * 600
                            }

                            NumberAnimation {
                                from: 0.5
                                to: 1.2
                                duration: 2000
                                easing.type: Easing.OutQuad
                            }

                        }

                    }

                }

                // Spinning disc
                UIcon {
                    anchors.centerIn: parent
                    iconName: "disc"
                    iconSize: Style.fontSizeXXXL * 3
                    color: Colors.mOnSurfaceVariant

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 8000
                        loops: Animation.Infinite
                        running: true
                    }

                }

            }

        }

        // MediaPlayer Main Content - use Loader for performance
        Loader {
            id: mainLoader

            anchors.fill: parent
            active: root.hasActivePlayer

            sourceComponent: Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Exceptionaly we put shadow on text and controls to ease readability
                UDropShadow {
                    anchors.fill: main
                    source: main
                    autoPaddingEnabled: true
                    shadowBlur: 1
                    shadowOpacity: 0.9
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                    shadowColor: "black"
                }

                ColumnLayout {
                    id: main

                    anchors.fill: parent
                    spacing: Style.marginS

                    // Metadata
                    ColumnLayout {
                        id: metadata

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignLeft
                        spacing: Style.marginXS

                        UText {
                            visible: MediaService.trackTitle !== ""
                            text: MediaService.trackTitle
                            pointSize: Style.fontSizeM
                            font.weight: Style.fontWeightBold
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            Layout.fillWidth: true
                        }

                        UText {
                            visible: MediaService.trackArtist !== ""
                            text: MediaService.trackArtist
                            color: Colors.mPrimary
                            pointSize: Style.fontSizeXS
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        UText {
                            visible: MediaService.trackAlbum !== ""
                            text: MediaService.trackAlbum
                            color: Colors.mOnSurfaceVariant
                            pointSize: Style.fontSizeS
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                    }

                    // Progress slider
                    Item {
                        id: progressWrapper

                        property real localSeekRatio: -1
                        property real lastSentSeekRatio: -1
                        property real seekEpsilon: 0.01
                        property real progressRatio: {
                            if (!MediaService.currentPlayer || MediaService.trackLength <= 0)
                                return 0;

                            const r = MediaService.currentPosition / MediaService.trackLength;
                            if (isNaN(r) || !isFinite(r))
                                return 0;

                            return Math.max(0, Math.min(1, r));
                        }
                        property real effectiveRatio: (MediaService.isSeeking && localSeekRatio >= 0) ? Math.max(0, Math.min(1, localSeekRatio)) : progressRatio

                        visible: (MediaService.currentPlayer && MediaService.trackLength > 0)
                        Layout.fillWidth: true
                        height: Style.baseWidgetSize * 0.5

                        Timer {
                            id: seekDebounce

                            interval: 75
                            repeat: false
                            onTriggered: {
                                if (MediaService.isSeeking && progressWrapper.localSeekRatio >= 0) {
                                    const next = Math.max(0, Math.min(1, progressWrapper.localSeekRatio));
                                    if (progressWrapper.lastSentSeekRatio < 0 || Math.abs(next - progressWrapper.lastSentSeekRatio) >= progressWrapper.seekEpsilon) {
                                        MediaService.seekByRatio(next);
                                        progressWrapper.lastSentSeekRatio = next;
                                    }
                                }
                            }
                        }

                        USlider {
                            id: progressSlider

                            anchors.fill: parent
                            from: 0
                            to: 1
                            stepSize: 0
                            snapAlways: false
                            enabled: MediaService.trackLength > 0 && MediaService.canSeek
                            heightRatio: 0.6
                            onMoved: {
                                progressWrapper.localSeekRatio = value;
                                seekDebounce.restart();
                            }
                            onPressedChanged: {
                                if (pressed) {
                                    MediaService.isSeeking = true;
                                    progressWrapper.localSeekRatio = value;
                                    MediaService.seekByRatio(value);
                                    progressWrapper.lastSentSeekRatio = value;
                                } else {
                                    seekDebounce.stop();
                                    MediaService.seekByRatio(value);
                                    MediaService.isSeeking = false;
                                    progressWrapper.localSeekRatio = -1;
                                    progressWrapper.lastSentSeekRatio = -1;
                                }
                            }
                        }

                        Binding {
                            target: progressSlider
                            property: "value"
                            value: progressWrapper.progressRatio
                            when: !MediaService.isSeeking
                        }

                    }

                    // Media controls
                    RowLayout {
                        spacing: Style.marginS
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter

                        UIconButton {
                            iconName: "media-prev"
                            visible: MediaService.canGoPrevious
                            onClicked: MediaService.canGoPrevious ? MediaService.previous() : {
                            }
                        }

                        UIconButton {
                            iconName: MediaService.isPlaying ? "media-pause" : "media-play"
                            visible: (MediaService.canPlay || MediaService.canPause)
                            onClicked: (MediaService.canPlay || MediaService.canPause) ? MediaService.playPause() : {
                            }
                        }

                        UIconButton {
                            iconName: "media-next"
                            visible: MediaService.canGoNext
                            onClicked: MediaService.canGoNext ? MediaService.next() : {
                            }
                        }

                    }

                }

            }

        }

    }

}
