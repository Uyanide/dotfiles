import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Modules.Bar.Misc
import qs.Noctalia
import qs.Services

GridLayout {
    id: buttonsGrid

    columns: 2
    columnSpacing: 10
    rowSpacing: 10
    Layout.margins: 10

    NIconButton {
        id: slowerButton

        baseSize: 32
        colorBg: Color.transparent
        colorBgHover: Colors.blue
        colorFg: Colors.blue
        icon: "arrow-bar-up"
        onClicked: {
            LyricsService.increaseOffset();
        }
    }

    NIconButton {
        id: playPauseButton

        baseSize: 32
        colorBg: Color.transparent
        colorBgHover: Colors.yellow
        colorFg: Colors.yellow
        icon: "arrow-bar-down"
        onClicked: {
            LyricsService.decreaseOffset();
        }
    }

    NIconButton {
        id: nextButton

        baseSize: 32
        colorBg: Color.transparent
        colorBgHover: Colors.green
        colorFg: Colors.green
        icon: "rotate-clockwise"
        onClicked: {
            LyricsService.resetOffset();
        }
    }

    NIconButton {
        id: fasterButton

        baseSize: 32
        colorBg: Color.transparent
        colorBgHover: Colors.red
        colorFg: Colors.red
        icon: "trash"
        onClicked: {
            LyricsService.clearCache();
        }
    }

    NIconButton {
        id: barLyricsButton

        baseSize: 32
        colorBg: SettingsService.showLyricsBar ? Colors.peach : Color.transparent
        colorBgHover: Colors.peach
        colorFg: SettingsService.showLyricsBar ? Colors.base : Colors.peach
        icon: "app-window"
        onClicked: {
            SettingsService.showLyricsBar = !SettingsService.showLyricsBar;
        }
    }

    NIconButton {
        id: textButton

        baseSize: 32
        colorBg: Color.transparent
        colorBgHover: Colors.subtext1
        colorFg: Colors.subtext1
        icon: "align-box-left-bottom"
        onClicked: {
            LyricsService.showLyricsText();
            controlCenterPanel.close();
        }
    }

}
