import QtQuick
import Quickshell
import qs.Constants
pragma Singleton

Singleton {
    id: root

    readonly property string primary: "Sour Gummy Light"
    readonly property string nerd: "Meslo LGM Nerd Font Mono"
    readonly property string sans: "Noto Sans"
    readonly property int small: Style.fontSizeS
    readonly property int medium: Style.fontSizeM
    readonly property int large: Style.fontSizeL
    readonly property int icon: 14 // for nerd font
}
