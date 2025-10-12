import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Modules.Panel.Cards
import qs.Noctalia
import qs.Services
import qs.Utils

NPanel {
    id: root

    // Positioning
    readonly property string controlCenterPosition: "top_left"
    property real topCardHeight: 120
    property real middleCardHeight: 100
    property real bottomCardHeight: 200

    preferredWidth: 480
    preferredHeight: topCardHeight + middleCardHeight + bottomCardHeight + Style.marginL * 4
    panelKeyboardFocus: false
    panelAnchorHorizontalCenter: controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_center")
    panelAnchorVerticalCenter: false
    panelAnchorLeft: controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_left")
    panelAnchorRight: controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.endsWith("_right")
    panelAnchorBottom: controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.startsWith("bottom_")
    panelAnchorTop: controlCenterPosition !== "close_to_bar_button" && controlCenterPosition.startsWith("top_")

    panelContent: Item {
        id: content

        property real cardSpacing: Style.marginL

        // Layout content
        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: content.cardSpacing
            spacing: content.cardSpacing

            // Top Card: profile + utilities
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: topCardHeight

                TopLeftCard {
                    Layout.fillWidth: true
                    Layout.maximumHeight: topCardHeight
                }

                LyricsControl {
                    Layout.preferredHeight: topCardHeight
                }

            }

            LyricsCard {
                Layout.fillWidth: true
                Layout.preferredHeight: middleCardHeight
            }

            // Media + stats column
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: bottomCardHeight
                spacing: content.cardSpacing

                SystemMonitorCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: bottomCardHeight
                }

                MediaCard {
                    Layout.preferredWidth: 270
                    Layout.preferredHeight: bottomCardHeight
                }

            }

        }

    }

}
