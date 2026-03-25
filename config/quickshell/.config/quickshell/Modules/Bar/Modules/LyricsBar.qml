import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services

Rectangle {
    radius: Style.radiusS
    color: Colors.mSurface
    border.color: Colors.mPrimary
    border.width: Style.borderS
    implicitHeight: Style.barHeight - Style.marginXS * 2
    implicitWidth: 600

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.marginM
        anchors.rightMargin: Style.marginM
        spacing: Style.marginXS

        Item {
            implicitWidth: parent.width - slowerButton.implicitWidth * 3 - parent.spacing * 3 - parent.anchors.leftMargin - parent.anchors.rightMargin
            Layout.fillHeight: true
            clip: true

            UText {
                text: LyricsService.lyrics.get(LyricsService.currentIndex)?.line || ""
                family: Fonts.sans
                pointSize: Style.fontSizeM
                maximumLineCount: 1
                anchors.verticalCenter: parent.verticalCenter
            }

        }

        UIconButton {
            id: slowerButton

            colorFg: Colors.mBlue
            iconName: "rotate-2"
            baseSize: parent.height - Style.marginXS * 2
            iconSize: Style.fontSizeM
            onClicked: {
                LyricsService.decreaseOffset();
            }
        }

        UIconButton {
            id: playPauseButton

            colorFg: Colors.mYellow
            iconName: "rotate-clockwise-2"
            baseSize: parent.height - Style.marginXS * 2
            iconSize: Style.fontSizeM
            onClicked: {
                LyricsService.increaseOffset();
            }
        }

        UIconButton {
            id: nextButton

            colorFg: Colors.mGreen
            iconName: "rotate-clockwise"
            baseSize: parent.height - Style.marginXS * 2
            iconSize: Style.fontSizeM
            onClicked: {
                LyricsService.resetOffset();
            }
        }

    }

}
