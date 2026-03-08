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

    ColumnLayout {
        id: lyricsColumn

        anchors.fill: parent
        anchors.margins: Style.marginS

        Repeater {
            model: LyricsService.lyrics

            UText {
                Layout.fillWidth: true
                text: modelData
                font.pointSize: index === LyricsService.currentIndex ? Style.fontSizeS : Style.fontSizeXS
                font.weight: index === LyricsService.currentIndex ? Style.fontWeightBold : Style.fontWeightRegular
                font.family: Fonts.sans
                color: index === LyricsService.currentIndex ? Colors.mOnSurface : Colors.mOnSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 1
            }

        }

    }

}
