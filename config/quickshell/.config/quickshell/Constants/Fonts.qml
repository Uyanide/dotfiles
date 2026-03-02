import QtQuick
import Quickshell
import qs.Constants
pragma Singleton

Singleton {
    id: root

    readonly property string primary: "LXGW WenKai"
    readonly property string nerd: "Meslo LGM Nerd Font Mono"
    readonly property string sans: "LXGW WenKai"
    readonly property int small: Style.fontSizeS
    readonly property int medium: Style.fontSizeM
    readonly property int large: Style.fontSizeL
    readonly property int icon: 14 // for nerd font
}
