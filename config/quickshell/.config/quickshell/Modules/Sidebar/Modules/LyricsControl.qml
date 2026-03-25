import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services

ColumnLayout {
    spacing: Style.marginS

    UText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        Layout.maximumWidth: buttonsGrid.width
        pointSize: Style.fontSizeS
        horizontalAlignment: Text.AlignHCenter
        text: "Offset (ms)"
    }

    UText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        Layout.maximumWidth: buttonsGrid.width
        horizontalAlignment: Text.AlignHCenter
        text: (LyricsService.lyricsOffset > 0 ? "+" + LyricsService.lyricsOffset : LyricsService.lyricsOffset)
    }

    UDivider {
        implicitWidth: buttonsGrid.implicitWidth
    }

    GridLayout {
        id: buttonsGrid

        columns: 2
        columnSpacing: Style.marginS
        rowSpacing: Style.marginS

        UIconButton {
            id: slowerButton

            baseSize: 32
            colorFg: Colors.mCyan
            iconName: "arrow-bar-up"
            onClicked: {
                LyricsService.decreaseOffset();
            }
        }

        UIconButton {
            id: playPauseButton

            baseSize: 32
            colorFg: Colors.mPurple
            iconName: "arrow-bar-down"
            onClicked: {
                LyricsService.increaseOffset();
            }
        }

        UIconButton {
            id: nextButton

            baseSize: 32
            colorFg: Colors.mGreen
            iconName: "rotate-clockwise"
            onClicked: {
                LyricsService.resetOffset();
            }
        }

        UIconButton {
            id: barLyricsButton

            baseSize: 32
            colorFg: Colors.mSky
            alwaysHover: LyricsService.showLyricsBar
            iconName: "app-window"
            onClicked: {
                LyricsService.toggleLyricsBar();
            }
        }

        UIconButton {
            baseSize: 32
            colorFg: Colors.mOrange
            alwaysHover: SunsetService.isEnabled
            iconName: "sunset-2"
            onClicked: SunsetService.toggleSunset()
        }

        UIconButton {
            baseSize: 32
            colorFg: Colors.mBlue
            alwaysHover: MediaService.autoSwitchingPaused
            iconName: "lock-square"
            onClicked: MediaService.toggleAutoSwitchingPaused()
        }

    }

}
