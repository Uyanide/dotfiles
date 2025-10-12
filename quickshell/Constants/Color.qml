import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
pragma Singleton

Singleton {
    id: root

    property color mPrimary: Colors.primary
    property color mOnPrimary: Colors.base
    property color mSecondary: Colors.primary
    property color mOnSecondary: Colors.base
    property color mTertiary: Colors.primary
    property color mOnTertiary: Colors.base
    property color mError: Colors.red
    property color mOnError: Colors.base
    property color mSurface: Colors.base
    property color mOnSurface: Colors.text
    property color mSurfaceVariant: Colors.surface
    property color mOnSurfaceVariant: Colors.text
    property color mOutline: Colors.primary
    property color mShadow: Colors.crust
    property color transparent: "transparent"
}
