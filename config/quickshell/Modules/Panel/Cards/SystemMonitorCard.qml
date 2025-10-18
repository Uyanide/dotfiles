import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Constants
import qs.Modules.Panel.Misc
import qs.Noctalia
import qs.Services
import qs.Utils

// Unified system card: monitors CPU, temp, memory, disk
NBox {
    id: root

    compact: true

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Style.marginXS
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
