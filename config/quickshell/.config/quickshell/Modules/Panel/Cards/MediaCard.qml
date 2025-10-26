import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Noctalia
import qs.Services
import qs.Utils

NBox {
    id: root

    // Background artwork that covers everything
    Item {
        anchors.fill: parent
        clip: true

        NImageRounded {
            id: bgArtImage

            anchors.fill: parent
            imagePath: MusicManager.trackArtUrl
            imageRadius: Style.radiusM
            visible: MusicManager.trackArtUrl !== ""
        }

        // Dark overlay for readability
        Rectangle {
            anchors.fill: parent
            color: Color.mSurfaceVariant
            opacity: 0.85
            radius: Style.radiusM
        }

        // Border
        Rectangle {
            anchors.fill: parent
            color: Color.transparent
            radius: Style.radiusM
        }

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
                    color: Color.mPrimary
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

    // Player selector - positioned at the very top
    Rectangle {
        id: playerSelectorButton

        property var currentPlayer: MusicManager.getAvailablePlayers()[MusicManager.selectedPlayerIndex]

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Style.marginXS
        anchors.leftMargin: Style.marginM
        anchors.rightMargin: Style.marginM
        height: Style.barHeight
        visible: MusicManager.getAvailablePlayers().length > 1
        radius: Style.radiusM
        color: Color.transparent
        Component.onCompleted: {
            MusicManager.selectedPlayerIndex = -1;
        }
        Component.onDestruction: {
            MusicManager.selectedPlayerIndex = -1;
        }

        RowLayout {
            anchors.fill: parent
            spacing: Style.marginS

            NIcon {
                icon: "caret-down"
                pointSize: Style.fontSizeXXL
                color: Color.mOnSurfaceVariant
            }

            NText {
                text: playerSelectorButton.currentPlayer ? playerSelectorButton.currentPlayer.identity : ""
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
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
                var players = MusicManager.getAvailablePlayers();
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
                playerContextMenu.openAtItem(playerSelectorButton, playerSelectorButton.width - playerContextMenu.width, playerSelectorButton.height);
            }
        }

        NContextMenu {
            id: playerContextMenu

            parent: root
            width: 200
            onTriggered: function(action) {
                var index = parseInt(action);
                if (!isNaN(index)) {
                    MusicManager.selectedPlayerIndex = index;
                    MusicManager.updateCurrentPlayer();
                }
            }
        }

    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM

        // No media player detected
        ColumnLayout {
            id: fallback

            visible: !main.visible
            spacing: Style.marginS

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Style.marginL

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Style.fontSizeXXXL * 4
                        Layout.preferredHeight: Style.fontSizeXXXL * 4

                        // Pulsating audio circles (background)
                        Repeater {
                            model: 3

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * (1 + index * 0.2)
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.color: Color.mOnSurfaceVariant
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
                        NIcon {
                            anchors.centerIn: parent
                            icon: "disc"
                            pointSize: Style.fontSizeXXXL * 3
                            color: Color.mOnSurfaceVariant

                            RotationAnimator on rotation {
                                from: 0
                                to: 360
                                duration: 8000
                                loops: Animation.Infinite
                                running: true
                            }

                        }

                    }

                    // Descriptive text
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.marginXS
                    }

                }

            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

        }

        // MediaPlayer Main Content
        ColumnLayout {
            id: main

            visible: MusicManager.currentPlayer && MusicManager.canPlay
            spacing: Style.marginS

            // Spacer to push content down
            Item {
                Layout.preferredHeight: Style.marginM
            }

            // Metadata at the bottom left
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                spacing: Style.marginXS

                NText {
                    visible: MusicManager.trackTitle !== ""
                    text: MusicManager.trackTitle
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightBold
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    maximumLineCount: 1
                }

                NText {
                    visible: MusicManager.trackArtist !== ""
                    text: MusicManager.trackArtist
                    color: Color.mPrimary
                    pointSize: Style.fontSizeS
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    maximumLineCount: 1
                }

                NText {
                    visible: MusicManager.trackAlbum !== ""
                    text: MusicManager.trackAlbum
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeM
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    maximumLineCount: 1
                }

            }

            // Progress slider
            Item {
                id: progressWrapper

                property real localSeekRatio: -1
                property real lastSentSeekRatio: -1
                property real seekEpsilon: 0.01
                property real progressRatio: {
                    if (!MusicManager.currentPlayer || MusicManager.trackLength <= 0)
                        return 0;

                    const r = MusicManager.currentPosition / MusicManager.trackLength;
                    if (isNaN(r) || !isFinite(r))
                        return 0;

                    return Math.max(0, Math.min(1, r));
                }
                property real effectiveRatio: (MusicManager.isSeeking && localSeekRatio >= 0) ? Math.max(0, Math.min(1, localSeekRatio)) : progressRatio

                visible: (MusicManager.currentPlayer && MusicManager.trackLength > 0)
                Layout.fillWidth: true
                height: Style.baseWidgetSize * 0.5

                Timer {
                    id: seekDebounce

                    interval: 75
                    repeat: false
                    onTriggered: {
                        if (MusicManager.isSeeking && progressWrapper.localSeekRatio >= 0) {
                            const next = Math.max(0, Math.min(1, progressWrapper.localSeekRatio));
                            if (progressWrapper.lastSentSeekRatio < 0 || Math.abs(next - progressWrapper.lastSentSeekRatio) >= progressWrapper.seekEpsilon) {
                                MusicManager.seekByRatio(next);
                                progressWrapper.lastSentSeekRatio = next;
                            }
                        }
                    }
                }

                NSlider {
                    id: progressSlider

                    anchors.fill: parent
                    from: 0
                    to: 1
                    stepSize: 0
                    snapAlways: false
                    enabled: MusicManager.trackLength > 0 && MusicManager.canSeek
                    heightRatio: 0.65
                    onMoved: {
                        progressWrapper.localSeekRatio = value;
                        seekDebounce.restart();
                    }
                    onPressedChanged: {
                        if (pressed) {
                            MusicManager.isSeeking = true;
                            progressWrapper.localSeekRatio = value;
                            MusicManager.seekByRatio(value);
                            progressWrapper.lastSentSeekRatio = value;
                        } else {
                            seekDebounce.stop();
                            MusicManager.seekByRatio(value);
                            MusicManager.isSeeking = false;
                            progressWrapper.localSeekRatio = -1;
                            progressWrapper.lastSentSeekRatio = -1;
                        }
                    }
                }

                Binding {
                    target: progressSlider
                    property: "value"
                    value: progressWrapper.progressRatio
                    when: !MusicManager.isSeeking
                }

            }

            // Media controls
            RowLayout {
                spacing: Style.marginS
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                NIconButton {
                    icon: "media-prev"
                    visible: MusicManager.canGoPrevious
                    onClicked: MusicManager.canGoPrevious ? MusicManager.previous() : {
                    }
                }

                NIconButton {
                    icon: MusicManager.isPlaying ? "media-pause" : "media-play"
                    visible: (MusicManager.canPlay || MusicManager.canPause)
                    onClicked: (MusicManager.canPlay || MusicManager.canPause) ? MusicManager.playPause() : {
                    }
                }

                NIconButton {
                    icon: "media-next"
                    visible: MusicManager.canGoNext
                    onClicked: MusicManager.canGoNext ? MusicManager.next() : {
                    }
                }

            }

        }

    }

}
