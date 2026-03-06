import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services

ColumnLayout {
    UText {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        Layout.maximumWidth: buttonsGrid.width
        Layout.bottomMargin: Style.marginS
        horizontalAlignment: Text.AlignHCenter
        text: (LyricsService.offset > 0 ? "+" + LyricsService.offset : LyricsService.offset) + " ms"
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
                LyricsService.increaseOffset();
            }
        }

        UIconButton {
            id: playPauseButton

            baseSize: 32
            colorFg: Colors.mPurple
            iconName: "arrow-bar-down"
            onClicked: {
                LyricsService.decreaseOffset();
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
            id: fasterButton

            baseSize: 32
            colorFg: Colors.mRed
            iconName: "trash"
            onClicked: {
                LyricsService.clearCache();
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
            id: textButton

            baseSize: 32
            colorFg: Colors.mYellow
            iconName: "align-box-left-bottom"
            onClicked: {
                LyricsService.showLyricsText();
                controlCenterPanel.close();
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
