import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs.Constants
import qs.Noctalia
import qs.Services
import qs.Utils

ColumnLayout {
    id: root

    readonly property bool hasPP: PowerProfileService.available

    spacing: Style.marginM

    NBox {
        id: whoamiBox

        property string uptimeText: "--"
        property string hostname: "--"

        function updateSystemInfo() {
            uptimeProcess.running = true;
            hostnameProcess.running = true;
        }

        Layout.fillWidth: true
        Layout.fillHeight: true

        RowLayout {
            id: content

            spacing: root.spacing
            anchors.fill: parent
            anchors.margins: root.spacing

            NImageCircled {
                width: Style.baseWidgetSize * 1.5
                height: Style.baseWidgetSize * 1.5
                imagePath: Quickshell.shellDir + "/Assets/Images/Avatar.jpg"
                fallbackIcon: "person"
                borderColor: Color.mPrimary
                borderWidth: Math.max(1, Style.borderM)
                Layout.alignment: Qt.AlignVCenter
                Layout.topMargin: Style.marginXS
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXXS

                NText {
                    text: `${Quickshell.env("USER") || "user"} @ ${whoamiBox.hostname}`
                    font.weight: Style.fontWeightBold
                    font.pointSize: Style.fontSizeL
                    font.capitalization: Font.Capitalize
                }

                NText {
                    text: "Uptime: " + whoamiBox.uptimeText
                    font.pointSize: Style.fontSizeM
                    color: Color.mOnSurfaceVariant
                }

            }

            Item {
                Layout.fillWidth: true
            }

        }

        // ----------------------------------
        // Uptime
        Timer {
            interval: 60000
            repeat: true
            running: true
            onTriggered: uptimeProcess.running = true
        }

        Process {
            id: uptimeProcess

            command: ["cat", "/proc/uptime"]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    var uptimeSeconds = parseFloat(this.text.trim().split(' ')[0]);
                    whoamiBox.uptimeText = Time.formatVagueHumanReadableDuration(uptimeSeconds);
                    uptimeProcess.running = false;
                }
            }

        }

        Process {
            id: hostnameProcess

            command: ["cat", "/etc/hostname"]
            running: true

            stdout: StdioCollector {
                onStreamFinished: {
                    whoamiBox.hostname = this.text.trim();
                    hostnameProcess.running = false;
                }
            }

        }

    }

    RowLayout {
        id: utilitiesRow

        Layout.fillWidth: true

        // Performance
        NIconButton {
            implicitHeight: 32
            implicitWidth: 32
            icon: PowerProfileService.getIcon(PowerProfile.Performance)
            enabled: hasPP
            opacity: enabled ? Style.opacityFull : Style.opacityMedium
            colorBgHover: Colors.red
            colorBg: (enabled && PowerProfileService.profile === PowerProfile.Performance) ? Colors.red : Color.transparent
            colorFg: (enabled && PowerProfileService.profile === PowerProfile.Performance) ? Color.mOnPrimary : Colors.red
            onClicked: PowerProfileService.setProfile(PowerProfile.Performance)
        }

        // Balanced
        NIconButton {
            implicitHeight: 32
            implicitWidth: 32
            icon: PowerProfileService.getIcon(PowerProfile.Balanced)
            enabled: hasPP
            opacity: enabled ? Style.opacityFull : Style.opacityMedium
            colorBgHover: Colors.blue
            colorBg: (enabled && PowerProfileService.profile === PowerProfile.Balanced) ? Colors.blue : Color.transparent
            colorFg: (enabled && PowerProfileService.profile === PowerProfile.Balanced) ? Color.mOnPrimary : Colors.blue
            onClicked: PowerProfileService.setProfile(PowerProfile.Balanced)
        }

        // Eco
        NIconButton {
            implicitHeight: 32
            implicitWidth: 32
            icon: PowerProfileService.getIcon(PowerProfile.PowerSaver)
            enabled: hasPP
            opacity: enabled ? Style.opacityFull : Style.opacityMedium
            colorBgHover: Colors.green
            colorBg: (enabled && PowerProfileService.profile === PowerProfile.PowerSaver) ? Colors.green : Color.transparent
            colorFg: (enabled && PowerProfileService.profile === PowerProfile.PowerSaver) ? Color.mOnPrimary : Colors.green
            onClicked: PowerProfileService.setProfile(PowerProfile.PowerSaver)
        }

        Item {
            Layout.fillWidth: true
        }

        // Lyrics Offset
        NText {
            text: `Lyrics Offset: ${LyricsService.offset >= 0 ? '+' : ''}${LyricsService.offset} ms`
            Layout.alignment: Qt.AlignVCenter
        }

    }

}
