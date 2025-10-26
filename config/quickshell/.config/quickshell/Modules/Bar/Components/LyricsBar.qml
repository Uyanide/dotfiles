import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Noctalia
import qs.Services

Rectangle {
    implicitHeight: parent.height
    radius: Style.radiusS
    color: Colors.base
    border.color: Colors.primary
    border.width: Style.borderS

    Connections {
        function onShowLyricsBarChanged() {
            visible = SettingsService.showLyricsBar;
            if (visible)
                LyricsService.startSyncing();
            else
                LyricsService.stopSyncing();
        }

        target: SettingsService
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.marginM
        anchors.rightMargin: Style.marginM
        spacing: Style.marginS

        Item {
            implicitWidth: parent.width - slowerButton.implicitWidth * 3 - parent.spacing * 3 - parent.anchors.leftMargin - parent.anchors.rightMargin
            Layout.fillHeight: true
            clip: true

            NText {
                text: LyricsService.lyrics[LyricsService.currentIndex] || ""
                family: Fonts.sans
                pointSize: Style.fontSizeS
                maximumLineCount: 1
                anchors.verticalCenter: parent.verticalCenter
            }

        }

        NIconButton {
            id: slowerButton

            baseSize: 24
            colorBg: Color.transparent
            colorBgHover: Colors.blue
            colorFg: Colors.blue
            icon: "rotate-2"
            onClicked: {
                LyricsService.increaseOffset();
            }
        }

        NIconButton {
            id: playPauseButton

            baseSize: 24
            colorBg: Color.transparent
            colorBgHover: Colors.yellow
            colorFg: Colors.yellow
            icon: "rotate-clockwise-2"
            onClicked: {
                LyricsService.decreaseOffset();
            }
        }

        NIconButton {
            id: nextButton

            baseSize: 24
            colorBg: Color.transparent
            colorBgHover: Colors.green
            colorFg: Colors.green
            icon: "rotate-clockwise"
            onClicked: {
                LyricsService.resetOffset();
            }
        }

    }

}
