import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.Components
import qs.Constants

// Rounded group container using the variant surface color.
// To be used in side panels and settings panes to group fields or buttons.
Rectangle {
    id: root

    property bool compact: false

    color: compact ? Colors.transparent : Colors.mSurfaceVariant
    radius: Style.radiusM
    layer.enabled: !compact

    layer.effect: MultiEffect {
        shadowEnabled: true
        blurMax: Style.shadowBlurMax
        shadowBlur: Style.shadowBlur
        shadowOpacity: Style.shadowOpacity
        shadowColor: Colors.mShadow
        shadowHorizontalOffset: Style.shadowHorizontalOffset
        shadowVerticalOffset: Style.shadowVerticalOffset
    }

}
