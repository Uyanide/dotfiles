import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
pragma Singleton

Singleton {
    id: root

    // Compatibility colors for noctalia modules
    readonly property color mPrimary: Colors.primary
    readonly property color mOnPrimary: Colors.base
    readonly property color mSecondary: Colors.primary
    readonly property color mOnSecondary: Colors.base
    readonly property color mTertiary: Colors.primary
    readonly property color mOnTertiary: Colors.base
    readonly property color mError: Colors.red
    readonly property color mOnError: Colors.base
    readonly property color mSurface: Colors.base
    readonly property color mOnSurface: Colors.text
    readonly property color mSurfaceVariant: Colors.surface
    readonly property color mOnSurfaceVariant: Colors.overlay1
    readonly property color mOutline: Colors.primary
    readonly property color mShadow: Colors.crust
    readonly property color transparent: "transparent"
}
