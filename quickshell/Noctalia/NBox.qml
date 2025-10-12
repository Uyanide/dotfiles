import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.Constants
import qs.Noctalia

// Rounded group container using the variant surface color.
// To be used in side panels and settings panes to group fields or buttons.
Rectangle {
    id: root

    property bool compact: false

    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    color: compact ? Color.transparent : Color.mSurfaceVariant
    radius: Style.radiusM
    layer.enabled: !compact

    layer.effect: DropShadow {
        horizontalOffset: 6
        verticalOffset: 6
        radius: 8
        samples: 12
        color: Qt.rgba(0, 0, 0, 0.3)
    }

}
