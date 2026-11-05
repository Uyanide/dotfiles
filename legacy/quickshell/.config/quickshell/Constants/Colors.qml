import QtQuick
import Quickshell
import Quickshell.Io
import qs.Constants
import qs.Services
import qs.Utils
pragma Singleton

Singleton {
    id: root

    // Part of material3 color scheme
    property color mPrimary: defaultColors.mPrimary
    property color mOnPrimary: defaultColors.mOnPrimary
    property color mError: defaultColors.mError
    property color mOnError: defaultColors.mOnError
    property color mSurface: defaultColors.mSurface
    property color mOnSurface: defaultColors.mOnSurface
    property color mSurfaceVariant: defaultColors.mSurfaceVariant
    property color mOnSurfaceVariant: defaultColors.mOnSurfaceVariant
    property color mOutline: defaultColors.mOutline
    property color mShadow: defaultColors.mShadow
    property color mHover: defaultColors.mHover
    property color mOnHover: defaultColors.mOnHover
    // Supplementary colors
    property color mPink: defaultColors.mPink
    property color mPurple: defaultColors.mPurple
    property color mRed: defaultColors.mRed
    property color mOrange: defaultColors.mOrange
    property color mYellow: defaultColors.mYellow
    property color mGreen: defaultColors.mGreen
    property color mCyan: defaultColors.mCyan
    property color mSky: defaultColors.mSky
    property color mBlue: defaultColors.mBlue
    property color mLavender: defaultColors.mLavender
    // Special colors
    property color distro: "#74c7ec"
    property color transparent: "#00000000"
    readonly property var cavaList: [mLavender, mBlue, mSky, mCyan, mGreen, mYellow, mOrange, mRed]
    readonly property var noteList: [mLavender, mBlue, mSky, mCyan, mGreen, mYellow, mOrange, mRed, mPurple, mPink]

    function reloadColors(newColors) {
        if (typeof newColors === "string") {
            try {
                newColors = JSON.parse(newColors);
            } catch (e) {
                Logger.e("Colors", "Failed to parse colors.json, using default colors. Error:", e);
                return ;
            }
        } else if (typeof newColors !== "object") {
            Logger.w("Colors", "Invalid colors data, using default colors. Data:", newColors);
            return ;
        }
        mPrimary = newColors.mPrimary || defaultColors.mPrimary;
        mOnPrimary = newColors.mOnPrimary || defaultColors.mOnPrimary;
        mError = newColors.mError || defaultColors.mError;
        mOnError = newColors.mOnError || defaultColors.mOnError;
        mSurface = newColors.mSurface || defaultColors.mSurface;
        mOnSurface = newColors.mOnSurface || defaultColors.mOnSurface;
        mSurfaceVariant = newColors.mSurfaceVariant || defaultColors.mSurfaceVariant;
        mOnSurfaceVariant = newColors.mOnSurfaceVariant || defaultColors.mOnSurfaceVariant;
        mOutline = newColors.mOutline || defaultColors.mOutline;
        mShadow = newColors.mShadow || defaultColors.mShadow;
        mHover = newColors.mHover || defaultColors.mHover;
        mOnHover = newColors.mOnHover || defaultColors.mOnHover;
        mPink = newColors.mPink || defaultColors.mPink;
        mPurple = newColors.mPurple || defaultColors.mPurple;
        mRed = newColors.mRed || defaultColors.mRed;
        mOrange = newColors.mOrange || defaultColors.mOrange;
        mYellow = newColors.mYellow || defaultColors.mYellow;
        mGreen = newColors.mGreen || defaultColors.mGreen;
        mCyan = newColors.mCyan || defaultColors.mCyan;
        mSky = newColors.mSky || defaultColors.mSky;
        mBlue = newColors.mBlue || defaultColors.mBlue;
        mLavender = newColors.mLavender || defaultColors.mLavender;
    }

    function setColor(name, value) {
        let state = ShellState.colorState;
        state[name] = value;
        ShellState.colorState = state;
    }

    function unsetColor(name) {
        let state = ShellState.colorState;
        delete state[name];
        ShellState.colorState = state;
    }

    Component.onCompleted: {
        reloadColors(ShellState.colorState);
    }

    Connections {
        function onColorStateChanged() {
            reloadTimer.restart();
        }

        target: ShellState
    }

    Timer {
        id: reloadTimer

        interval: 500
        running: false
        repeat: false
        onTriggered: {
            if (BackgroundService.isProcessing) {
                reloadTimer.restart();
                return ;
            }
            reloadColors(ShellState.colorState);
        }
    }

    QtObject {
        id: defaultColors

        readonly property color mPrimary: "#89b4fa"
        readonly property color mOnPrimary: "#11111b"
        readonly property color mError: "#f38ba8"
        readonly property color mOnError: "#11111b"
        readonly property color mSurface: "#1e1e2e"
        readonly property color mOnSurface: "#cdd6f4"
        readonly property color mSurfaceVariant: "#313244"
        readonly property color mOnSurfaceVariant: "#a6adc8"
        readonly property color mOutline: "#585b70"
        readonly property color mShadow: "#11111b"
        readonly property color mHover: "#45475a"
        readonly property color mOnHover: "#cdd6f4"
        readonly property color mPink: "#f5c2e7"
        readonly property color mPurple: "#cba6f7"
        readonly property color mRed: "#f38ba8"
        readonly property color mOrange: "#fab387"
        readonly property color mYellow: "#f9e2af"
        readonly property color mGreen: "#a6e3a1"
        readonly property color mCyan: "#94e2d5"
        readonly property color mSky: "#74c7ec"
        readonly property color mBlue: "#89b4fa"
        readonly property color mLavender: "#b4befe"
    }

}
