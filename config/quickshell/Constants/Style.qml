import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    /*
    Preset sizes for font, radii, ?
    */

    id: root

    // Font size
    property real fontSizeXXS: 8
    property real fontSizeXS: 9
    property real fontSizeS: 10
    property real fontSizeM: 11
    property real fontSizeL: 13
    property real fontSizeXL: 16
    property real fontSizeXXL: 18
    property real fontSizeXXXL: 24
    // Font weight
    property int fontWeightRegular: 400
    property int fontWeightMedium: 500
    property int fontWeightSemiBold: 600
    property int fontWeightBold: 700
    // Radii
    property int radiusXXS: 4
    property int radiusXS: 8
    property int radiusS: 12
    property int radiusM: 16
    property int radiusL: 20
    //screen Radii
    property int screenRadius: 20
    // Border
    property int borderS: 2
    property int borderM: 3
    property int borderL: 4
    // Margins (for margins and spacing)
    property int marginXXS: 2
    property int marginXS: 4
    property int marginS: 8
    property int marginM: 12
    property int marginL: 16
    property int marginXL: 24
    // Opacity
    property real opacityNone: 0
    property real opacityLight: 0.25
    property real opacityMedium: 0.5
    property real opacityHeavy: 0.75
    property real opacityAlmost: 0.95
    property real opacityFull: 1
    // Animation duration (ms)
    property int animationFast: 150
    property int animationNormal: 300
    property int animationSlow: 450
    property int animationSlowest: 1000
    // Delays
    property int tooltipDelay: 300
    property int tooltipDelayLong: 1200
    property int pillDelay: 500
    // Settings widgets base size
    property real baseWidgetSize: 33
    property real sliderWidth: 200
    // Bar Dimensions
    property real barHeight: 45
    property real capsuleHeight: 35
}
