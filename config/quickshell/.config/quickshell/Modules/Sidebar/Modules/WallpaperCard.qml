import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.Components
import qs.Constants
import qs.Services

RowLayout {
    implicitHeight: wallpaperImage.implicitHeight
    spacing: Style.marginS

    UImageRounded {
        id: wallpaperImage

        Layout.fillWidth: true
        height: Style.baseWidgetSize * 3.2 + Style.marginS * 3
        radius: Style.radiusM
        imagePath: BackgroundService.displayPath
        fallbackIcon: "wallpaper"
        layer.enabled: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: BackgroundService.openChooser()
            cursorShape: Qt.PointingHandCursor
        }

        Rectangle {
            visible: WallpaperCycle.enabled
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            width: Style.marginS
            height: parent.height * WallpaperCycle.timeUntilNextCycle / WallpaperCycle.cycleInterval
            color: Colors.mPrimary
            radius: Style.radiusS
        }

        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: Style.shadowBlurMax
            shadowBlur: Style.shadowBlur
            shadowOpacity: Style.shadowOpacity
            shadowColor: Colors.mShadow
            shadowHorizontalOffset: Style.shadowHorizontalOffset
            shadowVerticalOffset: Style.shadowVerticalOffset
        }

    }

    ColumnLayout {
        id: buttonsColumn

        spacing: Style.marginS

        UIconButton {
            baseSize: Style.baseWidgetSize * 0.8
            iconName: "player-track-prev"
            colorFg: Colors.mBlue
            onClicked: WallpaperCycle.applyPrev()
        }

        UIconButton {
            baseSize: Style.baseWidgetSize * 0.8
            iconName: "player-track-next"
            colorFg: Colors.mYellow
            onClicked: WallpaperCycle.applyNext()
        }

        UIconButton {
            baseSize: Style.baseWidgetSize * 0.8
            iconName: WallpaperCycle.enabled ? "player-pause" : "player-play"
            colorFg: WallpaperCycle.enabled ? Colors.mGreen : Colors.mRed
            alwaysHover: WallpaperCycle.enabled
            onClicked: WallpaperCycle.playPause()
        }

        UIconButton {
            baseSize: Style.baseWidgetSize * 0.8
            iconName: WallpaperCycle.shuffle ? "arrows-shuffle" : "repeat"
            colorFg: Colors.mPurple
            alwaysHover: WallpaperCycle.shuffle
            onClicked: WallpaperCycle.toggleShuffle()
        }

    }

}
