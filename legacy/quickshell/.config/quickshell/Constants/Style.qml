import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    // Font size
    readonly property real fontSizeXXS: 8
    readonly property real fontSizeXS: 9
    readonly property real fontSizeS: 10
    readonly property real fontSizeM: 11
    readonly property real fontSizeL: 13
    readonly property real fontSizeXL: 16
    readonly property real fontSizeXXL: 18
    readonly property real fontSizeXXXL: 24
    readonly property real fontNerd: 16
    // Font weight
    readonly property int fontWeightRegular: 400
    readonly property int fontWeightMedium: 500
    readonly property int fontWeightSemiBold: 600
    readonly property int fontWeightBold: 700
    // Radii
    readonly property int radiusXXS: 4
    readonly property int radiusXS: 8
    readonly property int radiusS: 12
    readonly property int radiusM: 16
    readonly property int radiusL: 20
    //screen Radii
    readonly property int screenRadius: 20
    // Border
    readonly property int borderS: 2
    readonly property int borderM: 3
    readonly property int borderL: 4
    // Margins (for margins and spacing)
    readonly property int marginXXS: 2
    readonly property int marginXS: 4
    readonly property int marginS: 8
    readonly property int marginM: 12
    readonly property int marginL: 16
    readonly property int marginXL: 24
    // Opacity
    readonly property real opacityNone: 0
    readonly property real opacityLight: 0.25
    readonly property real opacityMedium: 0.5
    readonly property real opacityHeavy: 0.75
    readonly property real opacityAlmost: 0.95
    readonly property real opacityFull: 1
    // Shadows
    readonly property real shadowOpacity: 0.85
    readonly property real shadowBlur: 1
    readonly property int shadowBlurMax: 22
    readonly property real shadowHorizontalOffset: 2
    readonly property real shadowVerticalOffset: 3
    // Animation duration (ms)
    readonly property int animationFast: 150
    readonly property int animationNormal: 300
    readonly property int animationSlow: 450
    readonly property int animationSlowest: 1000
    // Settings widgets base size
    readonly property int baseWidgetSize: 33
    readonly property int sliderWidth: 200
    // Bar Dimensions
    readonly property int barHeight: 45
    readonly property int sidebarWidth: 360
    readonly property int capsuleHeight: 35
}
