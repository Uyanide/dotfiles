import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Modules.Sidebar.Components
import qs.Modules.Sidebar.Modules
import qs.Services

Variants {
    model: Quickshell.screens

    Item {
        property var modelData

        SidebarWrap {
            screen: modelData
            isLeft: true

            contentComponent: ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                WeatherCard {
                    Layout.fillWidth: true
                }

                CalendarMonthCard {
                    Layout.fillWidth: true
                }

                LyricsCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    LyricsControl {
                    }

                    MediaCard {
                        Layout.fillWidth: true
                    }

                }

                ConnectionCard {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }

            }

        }

        SidebarWrap {
            screen: modelData
            isLeft: false

            contentComponent: ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                PowerMenuCard {
                    Layout.fillWidth: true
                }

                WallpaperCard {
                    Layout.fillWidth: true
                }

                NotificationNoteToggleCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

            }

        }

    }

}
