import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Constants
import qs.Services
import qs.Utils

UBox {
    id: root

    // Internal state
    readonly property var now: Time.now
    readonly property bool weatherReady: LocationService.data.weather !== null
    // Expose current month/year for potential synchronization with CalendarMonthCard
    readonly property int currentMonth: now.getMonth()
    readonly property int currentYear: now.getFullYear()

    implicitHeight: (60) + Style.marginM * 2
    color: Colors.mPrimary

    ColumnLayout {
        id: capsuleColumn

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.topMargin: Style.marginM
        anchors.bottomMargin: Style.marginM
        anchors.rightMargin: clockLoader.width + Style.marginXL * 2
        anchors.leftMargin: Style.marginXL
        spacing: 0

        // Combined layout for date, month year, location and time-zone
        RowLayout {
            Layout.fillWidth: true
            height: 60
            clip: true
            spacing: Style.marginS

            // Today day number
            UText {
                Layout.preferredWidth: implicitWidth
                elide: Text.ElideNone
                clip: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                text: root.now.getDate()
                pointSize: Style.fontSizeXXXL * 1.5
                font.weight: Style.fontWeightBold
                color: Colors.mOnPrimary
            }

            // Month, year, location
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.bottomMargin: Style.marginXXS
                Layout.topMargin: -Style.marginXXS
                spacing: -Style.marginXS

                RowLayout {
                    spacing: Style.marginS

                    UText {
                        text: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][root.currentMonth]
                        pointSize: Style.fontSizeXL * 1.1
                        font.weight: Style.fontWeightBold
                        color: Colors.mOnPrimary
                        Layout.alignment: Qt.AlignBaseline
                        elide: Text.ElideRight
                    }

                    UText {
                        text: `${root.currentYear}`
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightBold
                        color: Qt.alpha(Colors.mOnPrimary, 0.7)
                        Layout.alignment: Qt.AlignBaseline
                    }

                }

                RowLayout {
                    spacing: 0

                    UText {
                        text: {
                            if (!root.weatherReady)
                                return "Loading weather...";

                            const chunks = SettingsService.location.split(",");
                            return chunks[0];
                        }
                        pointSize: Style.fontSizeM
                        color: Colors.mOnPrimary
                        Layout.maximumWidth: 150
                        elide: Text.ElideRight
                    }

                    UText {
                        text: root.weatherReady && ` (${LocationService.data.weather.timezone_abbreviation})`
                        pointSize: Style.fontSizeXS
                        color: Qt.alpha(Colors.mOnPrimary, 0.7)
                    }

                }

            }

            // Spacer
            Item {
                Layout.fillWidth: true
            }

        }

    }

    // Analog/Digital clock
    UClock {
        id: clockLoader

        anchors.right: parent.right
        anchors.rightMargin: Style.marginXL
        anchors.verticalCenter: parent.verticalCenter
        clockStyle: "analog"
        progressColor: Colors.mOnPrimary
        Layout.alignment: Qt.AlignVCenter
        now: root.now
    }

}
