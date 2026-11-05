import QtQuick
import Quickshell
import qs.Services
pragma Singleton

Singleton {
    property var _leftSideBarMap: ({
    })
    property var _rightSideBarMap: ({
    })
    property var _currentLeftSidebar: null
    property var _currentRightSidebar: null
    // property int leftOffset: _currentLeftSidebar?.barWidth ?? 0
    // property int rightOffset: _currentRightSidebar?.barWidth ?? 0
    property bool focusMode: Niri.hasFocusedWindow || _currentLeftSidebar !== null || _currentRightSidebar !== null

    function getLeftSidebar(screen) {
        return _leftSideBarMap[screen] || null;
    }

    function getRightSidebar(screen) {
        return _rightSideBarMap[screen] || null;
    }

    // screen should be string, like "eDP-1"
    function registerLeft(screen, sidebar) {
        _leftSideBarMap[screen] = sidebar;
    }

    function registerRight(screen, sidebar) {
        _rightSideBarMap[screen] = sidebar;
    }

    function toggleLeft() {
        if (_currentLeftSidebar) {
            _currentLeftSidebar.close();
            _currentLeftSidebar = null;
        } else {
            const screen = Niri.focusedOutput;
            const sidebar = _leftSideBarMap[screen];
            if (sidebar) {
                sidebar.open();
                _currentLeftSidebar = sidebar;
            }
        }
    }

    function toggleRight() {
        if (_currentRightSidebar) {
            _currentRightSidebar.close();
            _currentRightSidebar = null;
        } else {
            const screen = Niri.focusedOutput;
            const sidebar = _rightSideBarMap[screen];
            if (sidebar) {
                sidebar.open();
                _currentRightSidebar = sidebar;
            }
        }
    }

}
