import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services
import qs.Utils

UBox {
    id: lyricsBox

    Component.onCompleted: {
        LyricsService.registerComponent("LyricsCard");
    }
    Component.onDestruction: {
        LyricsService.unregisterComponent("LyricsCard");
    }

    UText {
        anchors.centerIn: parent
        visible: LyricsService.isFetchingLyrics || LyricsService.lyrics.count === 0
        text: LyricsService.isFetchingLyrics ? "Fetching..." : "No lyrics available"
        color: Colors.mOnSurfaceVariant
    }

    ListView {
        id: lyricsList

        anchors.fill: parent
        anchors.margins: Style.marginS
        spacing: Style.marginM
        model: LyricsService.lyrics
        currentIndex: LyricsService.currentIndex
        clip: true
        visible: !LyricsService.isFetchingLyrics && LyricsService.lyrics.count > 0
        onCurrentIndexChanged: {
            if (currentIndex >= 0)
                positionViewAtIndex(currentIndex, ListView.Center);

        }
        Component.onCompleted: {
            Qt.callLater(function() {
                if (currentIndex >= 0)
                    positionViewAtIndex(currentIndex, ListView.Center);

            });
        }

        delegate: UText {
            width: ListView.view.width
            text: model.line || ""
            font.pointSize: ListView.isCurrentItem ? Style.fontSizeS : Style.fontSizeXS
            font.weight: ListView.isCurrentItem ? Style.fontWeightBold : Style.fontWeightRegular
            font.family: Fonts.sans
            color: ListView.isCurrentItem ? Colors.mOnSurface : Colors.mOnSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            wrapMode: Text.WrapAnywhere

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    LyricsService.seekToLyric(index);
                }
            }

        }

    }

}
