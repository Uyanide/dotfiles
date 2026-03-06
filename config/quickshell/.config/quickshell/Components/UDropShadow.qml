import QtQuick
import QtQuick.Effects
import qs.Constants

// Unified shadow system
Item {
    id: root

    required property var source
    property bool autoPaddingEnabled: false
    property real shadowHorizontalOffset: Style.shadowHorizontalOffset
    property real shadowVerticalOffset: Style.shadowVerticalOffset
    property real shadowOpacity: Style.shadowOpacity
    property color shadowColor: Colors.mShadow
    property real shadowBlur: Style.shadowBlur

    layer.enabled: true

    layer.effect: MultiEffect {
        source: root.source
        shadowEnabled: true
        blurMax: Style.shadowBlurMax
        shadowBlur: root.shadowBlur
        shadowOpacity: root.shadowOpacity
        shadowColor: root.shadowColor
        shadowHorizontalOffset: root.shadowHorizontalOffset
        shadowVerticalOffset: root.shadowVerticalOffset
        autoPaddingEnabled: root.autoPaddingEnabled
    }

}
