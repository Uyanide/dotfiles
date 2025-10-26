import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Noctalia
import qs.Services
import qs.Utils

NBox {
    id: lyricsBox

    Component.onCompleted: {
        LyricsService.startSyncing();
    }
    Component.onDestruction: {
        LyricsService.stopSyncing();
    }

    ColumnLayout {
        id: lyricsColumn

        anchors.fill: parent
        anchors.margins: Style.marginS

        Repeater {
            model: LyricsService.lyrics

            NText {
                Layout.fillWidth: true
                text: modelData
                font.pointSize: index === LyricsService.currentIndex ? Style.fontSizeM : Style.fontSizeS
                font.weight: index === LyricsService.currentIndex ? Style.fontWeightBold : Style.fontWeightRegular
                font.family: Fonts.sans
                color: index === LyricsService.currentIndex ? Color.mOnSurface : Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 1
            }

        }

    }

}
