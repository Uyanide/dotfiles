import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Modules.Bar.Components
import qs.Constants
import qs.Services
import qs.Utils

Rectangle {
  id: root

  property ShellScreen screen
  property var activeTrayItem: null
  property var pinnedIds: []
  property var excludeIds: []

  implicitWidth: trayFlow.implicitWidth > 0 ? trayFlow.implicitWidth + 20 : 0
  implicitHeight: parent.height
  radius: 0
  color: Colors.transparent

  Layout.alignment: Qt.AlignVCenter

  Flow {
    id: trayFlow
    anchors.centerIn: parent
    spacing: 8
    flow: Flow.LeftToRight

    Repeater {
      id: repeater
      model: SystemTray.items

      delegate: Item {
        width: 18
        height: 18
        visible: {
          if (!modelData) return false
          if (pinnedIds.length > 0) return pinnedIds.includes(modelData.id)
          if (excludeIds.length > 0) return !excludeIds.includes(modelData.id)
          return true
        }

        IconImage {
          id: trayIcon

          property ShellScreen screen: root.screen

          anchors.centerIn: parent
          width: 14
          height: 14
          smooth: false
          asynchronous: true
          backer.fillMode: Image.PreserveAspectFit
          source: {
            let icon = modelData?.icon || ""
            if (!icon) {
              return ""
            }

            // Process icon path
            if (icon.includes("?path=")) {
              const chunks = icon.split("?path=")
              const name = chunks[0]
              const path = chunks[1]
              const fileName = name.substring(name.lastIndexOf("/") + 1)
              return `file://${path}/${fileName}`
            }
            return icon
          }
          opacity: status === Image.Ready ? 1 : 0
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          onClicked: mouse => {
                       if (!modelData) {
                         return
                       }

                       if (mouse.button === Qt.LeftButton) {
                         // Close any open menu first
                         trayPanel.close()

                         if (!modelData.onlyMenu) {
                           modelData.activate()
                         }
                       } else if (mouse.button === Qt.MiddleButton) {
                         // Close any open menu first
                         trayPanel.close()

                         modelData.secondaryActivate && modelData.secondaryActivate()
                       } else if (mouse.button === Qt.RightButton) {
                         if (trayPanel && trayPanel.visible) {
                           // Right-click the same icon toggles menu off.
                           if (root.activeTrayItem === modelData) {
                             trayPanel.close()
                             return
                           }

                           // Switch directly to another tray item's menu.
                           trayPanel.close()
                         }

                         if (modelData.hasMenu && modelData.menu && trayMenu.item) {
                           trayPanel.open()

                           // Position menu based on bar position
                           let menuX, menuY
                             // For horizontal bars: center horizontally and position below
                             menuX = (width / 2) - (trayMenu.item.width / 2)
                             menuY = root.height
                           trayMenu.item.menu = modelData.menu
                           root.activeTrayItem = modelData
                           trayMenu.item.showAt(parent, menuX, menuY)
                         } else {
                           Logger.d("Tray", "No menu available for", modelData.id, "or trayMenu not set")
                         }
                       }
                     }
        }
      }
    }
  }

  PanelWindow {
    id: trayPanel
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    visible: false
    color: Colors.transparent
    screen: root.screen

    function open() {
      visible = true
      PanelService.willOpenPanel(trayPanel)
    }

    function close() {
      visible = false
      root.activeTrayItem = null
      if (trayMenu.item) {
        trayMenu.item.hideMenu()
      }
    }

    // Clicking outside of the rectangle to close
    MouseArea {
      anchors.fill: parent
      onClicked: trayPanel.close()
    }

    Loader {
      id: trayMenu
    Component.onCompleted: {
        setSource("./TrayMenu.qml", {
            "screen": root.screen
        })
    }
    }
  }
}
