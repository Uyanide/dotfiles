import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Modules.Panel.Misc
import qs.Noctalia
import qs.Services
import qs.Utils

ColumnLayout {
    id: root

    spacing: 0

    RowLayout {
        id: sunsetControlRow

        Layout.fillWidth: true

        NIconButton {
            id: barLyricsButton

            implicitHeight: 32
            implicitWidth: 32
            colorBg: SunsetService.isRunning ? Colors.flamingo : Color.transparent
            colorBgHover: Colors.flamingo
            colorFg: SunsetService.isRunning ? Colors.base : Colors.flamingo
            icon: "sunset-2"
            onClicked: SunsetService.toggleSunset()
        }

        NText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: SunsetService.isRunning ? "Temp: " + SunsetService.temperature + " K" : "Sunset Off"
        }

    }

    NBox {
        id: monitors

        compact: true
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: Style.marginS
            spacing: Style.marginS

            MonitorSlider {
                icon: "cpu-usage"
                value: SystemStatService.cpuUsage
                from: 0
                to: 100
                colorFill: Colors.teal
                Layout.fillWidth: true
            }

            MonitorSlider {
                icon: "memory"
                value: SystemStatService.memPercent
                from: 0
                to: 100
                colorFill: Colors.green
                Layout.fillWidth: true
            }

            MonitorSlider {
                icon: "cpu-temperature"
                value: SystemStatService.cpuTemp
                from: 0
                to: 100
                colorFill: Colors.yellow
                Layout.fillWidth: true
            }

            MonitorSlider {
                icon: "storage"
                value: SystemStatService.diskPercent
                from: 0
                to: 100
                colorFill: Colors.peach
                Layout.fillWidth: true
            }

        }

    }

}
